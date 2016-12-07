#Copyright owned by CloudLayer

package pcenter::incormanage;
use strict;
use Getopt::Long;
use pcenter::PPCcli qw(SUCCESS EXPECT_ERROR RC_ERROR NR_ERROR);
use pcenter::PPCdb;
use pcenter::Usage;
use pcenter::NodeRange;
use Data::Dumper;
use pcenter::MsgUtils qw(verbose_message);
use pcenter::Utils;
use Expect;
use DBI;
use LWP::UserAgent;
use LWP::Simple;
use Data::Dumper;  
use JSON;
use Config::Tiny;
#use File::Lockfile;

##########################################################################
# Parse the command line for options and operands
##########################################################################
sub parse_args {
    #pcenter::MsgUtils->log("#######################[#".Dumper(@_), "info");
    my $request = shift;
    my %opt     = ();
    my $cmd     = $request->{command};
    my $args    = $request->{arg};

    #############################################
    # Responds with usage statement
    #############################################
    local *usage = sub { 
        my $usage_string = pcenter::Usage->getUsage($cmd);
        return( [ $_[0], $usage_string] );
    };
    #############################################
    # Process command-line arguments
    #############################################
    if ( !defined( $args )) {
        $request->{method} = $cmd;
        return( \%opt );
    }
    #############################################
    # Checks case in GetOptions, allows opts
    # to be grouped (e.g. -vx), and terminates
    # at the first unrecognized option.
    #############################################
    @ARGV = @$args;
    $Getopt::Long::ignorecase = 0;
    Getopt::Long::Configure( "bundling" );

    if ( !GetOptions( \%opt, qw(V|verbose t=s u=s p=s v=s) )) {
        return( usage("There is command not support") );
    }
    ####################################
    # Check for "-" with no option
    ####################################
    if ( grep(/^-$/, @ARGV )) {
        return(usage( "Missing option: -" ));
    }
    ####################################
    # No operands - add command name 
    ####################################
    $request->{method} = $cmd; 
    return( \%opt );

}


############################################################################
# Creates/changes logical partitions 
##########################################################################
sub incormanage {
    #pcenter::MsgUtils->log("#######################[#".Dumper(@_), "info");
    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my $hwtype  = @$exp[2];
    my $opt     = $request->{opt};
    my @values  = ();
    my $Rc = undef;
    my $return_value = ();
    my @vmnames = split(/,/,$opt->{v});#"aixvm111";

    my $token = generate_token($opt);

    foreach my $vmname(@vmnames){
	    my @network_value = generate_network($token,$vmname);
	    my $flavor_value = generate_flavor($token,$vmname);
	    my $image_value = generate_image($token,$vmname);#"1c153881-9e86-4b50-929d-dbf01878333b";

	    my %vm_parameter;
	    $vm_parameter{image_id} = $image_value;
	    $vm_parameter{flavor_id} = $flavor_value;
	    $vm_parameter{vm_name} = $vmname;
	    $vm_parameter{vm_ports} = \@network_value;
	    my $vm_ret_val = create_vm($token,\%vm_parameter);
    }

    push @values, ["success","$token",0];
    return( \@values );
}

sub create_vm
{
	my $token = shift;
	my $vm_parameter = shift;
	my $token_id = $token->{access}->{token}->{id};
	my $url;
	my $service_info = $token->{access}->{serviceCatalog};
	foreach my $tmp_value (@$service_info){
		if ($tmp_value->{type} eq "compute"){
			$url = $tmp_value->{endpoints}[0]->{adminURL};
			last;
		}
	}


	my %flavor_data = {};
	my $vm_return_value = ();
	
	$url .= "/servers";
	
	my $vm_name = $vm_parameter->{vm_name};
	my $image_id = $vm_parameter->{image_id};
	my $flavor_id = $vm_parameter->{flavor_id};
	my $vm_ports ;
	foreach my $tmp_port_value (@{$vm_parameter->{vm_ports}}){
		$vm_ports .= "{\"port\":\"$tmp_port_value\"},";
	}	
	$vm_ports =~ s/^(.*),$/$1/;

	my $post_data = "{\"server\":{\"name\": \"$vm_name\",\"imageRef\": \"$image_id\",\"flavorRef\": \"$flavor_id\",\"networks\":[$vm_ports]}}";
	my $vm_post_value = post_request($token_id,$url,$post_data)->decoded_content;	
    	my $vm_post_data_hash = decode_json($vm_post_value);
	$vm_return_value = $vm_post_data_hash->{server}->{id};	
	return $vm_return_value;
}



sub get_subnet_id
{

	my $token_id = shift;
	my $url	= shift;
	my $vm_ip = shift;
	my $gateway_ip = shift;
	my $vmname = shift;
	my $network_return_value = shift;

	my $cidr = $vm_ip;	
	$cidr =~ s/(\d+).(\d+).(\d+).(\d+)./$1.$2.$3.0\/24/;
	my $subnet_return_value = ();

	my $subnet_url = $url."v2.0/subnets";
	my $subnet_get_data = get_request($token_id,$subnet_url)->decoded_content;	
    	my $subnet_get_data_hash = decode_json($subnet_get_data);
	my $create_subnet_flag = 0;
	foreach my $tmp_subnet_value (@{$subnet_get_data_hash->{subnets}}){
		if(($tmp_subnet_value->{'network_id'} eq $network_return_value) && ($tmp_subnet_value->{'cidr'} eq $cidr)){
			my $allocation_pools = $tmp_subnet_value->{'allocation_pools'};
			foreach my $temp_pools (@$allocation_pools){
				#if(($vm_ip gt $temp_pools->{'start'} ) and ($vm_ip lt $temp_pools->{'end'})){
				if(($vm_ip lt \$temp_pools->{'end'} ) and ($vm_ip gt $temp_pools->{'start'} )){
					$create_subnet_flag = 5;
					$subnet_return_value = $tmp_subnet_value->{'id'};
					last;
				}else{
					$create_subnet_flag = 2;
				}
				
			}
			if(1 == $create_subnet_flag){
				last;
			}
		}
	}

	if(5 >  $create_subnet_flag){
		my $start_num = '2';
		my $end_num = '254';
		if(2 == $create_subnet_flag){
			$start_num = $vm_ip; 
			$start_num =~ s/(\d+).(\d+).(\d+).(\d+)./$4/;
			$end_num = $start_num; 
		}
		my $start_ip =$vm_ip;
		$start_ip =~ s/(\d+).(\d+).(\d+).(\d+)./$1.$2.$3.$start_num/;
		my $end_ip =$vm_ip;
		$end_ip =~ s/(\d+).(\d+).(\d+).(\d+)./$1.$2.$3.$end_num/;

		my $create_subnet_parameter = "{\"name\": \"$vmname\",\"enable_dhcp\": true,
		   \"network_id\":\"$network_return_value\",\"ip_version\":4,\"cidr\":\"$cidr\",
		   \"gateway_ip\":\"$gateway_ip\",\"allocation_pools\":[{\"start\":\"$start_ip\",\"end\":\"$end_ip\"}]}";
		my $post_data = "{\"subnet\":$create_subnet_parameter}";

		my $subnet_post_value = post_request($token_id,$subnet_url,$post_data)->decoded_content;	
		my $subnet_post_data_hash = decode_json($subnet_post_value);
		$subnet_return_value = $subnet_post_data_hash->{subnet}->{id};	

	}
	
	return $subnet_return_value;

}

sub get_net_id
{
	my $token_id = shift;
	my $url	= shift;
	my $vlan_id = shift;
	my $vmname = shift;
	my $network_url = $url."v2.0/networks";
        my $network_return_value ;
	
	my $network_get_data = get_request($token_id,$network_url)->decoded_content;	
    	my $network_get_data_hash = decode_json($network_get_data);

	my $create_net_flag = ();
	foreach my $tmp_network_value (@{$network_get_data_hash->{networks}}){
		if ($tmp_network_value->{'provider:segmentation_id'} eq $vlan_id){
			$network_return_value = $tmp_network_value->{'id'};	
			$create_net_flag = 1;
			last;
		}
	}

	unless($create_net_flag){
		my $create_network_parameter = "{\"name\": \"$vmname\",\"admin_state_up\": true,\"provider:network_type\":\"vxlan\",\"provider:segmentation_id\":\"$vlan_id\"}";
		my $post_data = "{\"network\":$create_network_parameter}";
		my $network_post_value = post_request($token_id,$network_url,$post_data)->decoded_content;	
		my $network_post_data_hash = decode_json($network_post_value);
		$network_return_value = $network_post_data_hash->{network}->{id};	
	}

	return $network_return_value;
}

sub get_port_id
{
	my $token_id = shift;
	my $url	= shift;
	my $port_ip = shift;
	my $network_return_value = shift;
	my $subnet_return_value = shift;
	my $vmname = shift;


	my $port_return_value = ();
	my $port_url = $url."v2.0/ports";

	my $port_get_data = get_request($token_id,$port_url)->decoded_content;	
    	my $port_get_data_hash = decode_json($port_get_data);

	my $create_port_flag = ();
	my $tmp_ports = $port_get_data_hash->{ports};
	foreach my $tmp_port_value (@{$port_get_data_hash->{ports}}){
	#	if (($tmp_port_value->{'network_id'} eq $network_return_value) && ($tmp_port_value->{'network_id'} eq "DOWN") ){
		if (($tmp_port_value->{'network_id'} eq $network_return_value) ){
			my $tmp_ips_hash = $tmp_port_value->{fixed_ips};	
			foreach my $temp_fixed_ips (@$tmp_ips_hash){
				if($temp_fixed_ips->{'ip_address'} eq $port_ip ){
					$port_return_value = $tmp_port_value->{'id'};	
					$create_port_flag = 1;
					last;
				}
			}
			if(1 == $create_port_flag){
				last;	
			}
		}
	}
	unless($create_port_flag){
		my $create_ports_parameter = "{\"name\": \"$vmname\",\"admin_state_up\": true,
		   \"network_id\":\"$network_return_value\",\"binding:vnic_type\":\"normal\",
		   \"fixed_ips\":[{\"subnet_id\":\"$subnet_return_value\",\"ip_address\":\"$port_ip\"}]}";
		my $post_data = "{\"port\":$create_ports_parameter}";

		my $ports_post_value = post_request($token_id,$port_url,$post_data)->decoded_content;	
		my $ports_post_data_hash = decode_json($ports_post_value);
		$port_return_value = $ports_post_data_hash->{port}->{id};		

	}
	return $port_return_value ;
}

sub generate_network
{
	my $token = shift;
	my $vmname = shift;
	my @return_ports = ();
	my $token_id = $token->{access}->{token}->{id};
	my $url;
	my $service_info = $token->{access}->{serviceCatalog};
	foreach my $tmp_value (@$service_info){
		if ($tmp_value->{type} eq "network"){
			$url = $tmp_value->{endpoints}[0]->{adminURL};
			last;
		}
	}

	#create network
	my $network_return_value = ();
	my $network_url = $url."v2.0/networks";
	my @return_values;
	my $eths = get_table_values("eth","t_vlan",$vmname);
	foreach my $tmp_eth (@$eths){
		my $eth_vlan = get_table_value("vlan","t_vlan","eth",$tmp_eth->{eth});
		my $eth_ip = get_table_value("ip","t_network","eth",$tmp_eth->{eth});
		my $eth_gateway = get_table_value("gateway","t_network","eth",$tmp_eth->{eth});

		my $net_id = get_net_id($token_id,$url,$eth_vlan->{'vlan'},$vmname);  
		my $subnet_id = get_subnet_id($token_id,$url,$eth_ip->{'ip'},$eth_gateway->{'gateway'},$vmname,$net_id);  
		my $port_id = get_port_id($token_id,$url,$eth_ip->{'ip'},$net_id,$subnet_id,$vmname);
		push @return_ports,$port_id;	
	}
	return  @return_ports;	
}

sub get_table_values
{
	my $condition_key = shift;
	my $table_name = shift;
	my $search_key = shift;
	my $dict = get_db_user_passwd();
	my ($host,$db,$username,$password) = split(':',$dict);
	my  $dbd = DBI->connect("DBI:mysql:$db:$host", "$username", "$password");
	my $pre = $dbd->prepare( qq{SELECT $condition_key  FROM $table_name where lpar_name="$search_key" ;});
	$pre->execute();
	my @return_value;
	while (my $tmp_value = $pre->fetchrow_hashref()){
		push @return_value,$tmp_value;
	}
	$pre->finish();
	$dbd->disconnect();
	return \@return_value;
	
}

sub get_table_value
{
	my $condition_key = shift;
	my $table_name = shift;
	my $search_key = shift;
	my $search_value = shift;
	my $dict = get_db_user_passwd();
	my ($host,$db,$username,$password) = split(':',$dict);
	my  $dbd = DBI->connect("DBI:mysql:$db:$host", "$username", "$password");
	my $pre = $dbd->prepare( qq{SELECT $condition_key  FROM $table_name where $search_key="$search_value" ;});
	$pre->execute();
	my $return_value = $pre->fetchrow_hashref();
	$pre->finish();
	$dbd->disconnect();
	return $return_value;
	
} 





sub generate_flavor
{
	my $token = shift;
	my $vmname = shift;
	my $token_id = $token->{access}->{token}->{id};
	my $url;
	my $service_info = $token->{access}->{serviceCatalog};
	foreach my $tmp_value (@$service_info){
		if ($tmp_value->{type} eq "compute"){
			$url = $tmp_value->{endpoints}[0]->{adminURL};
			last;
		}
	}
	my %flavor_data = {};
	my $flavor_return_value = ();

	
	$flavor_data{name} = $vmname;
	$flavor_data{vcpus} = ();
	$flavor_data{ram} = ();
	$flavor_data{disk} = ();

	 my $dict = get_db_user_passwd();
	 my ($host,$db,$username,$password) = split(':',$dict);
	 my  $dbd = DBI->connect("DBI:mysql:$db:$host", "$username", "$password");
	 my $pre = $dbd->prepare( qq{SELECT memory_total,cpu_logic  FROM t_vm where lpar_name="$vmname" ;});
	 $pre->execute();
	 my $info = $pre->fetchrow_hashref();
	 $pre->finish();
	 $dbd->disconnect();

	$flavor_data{vcpus} = $info->{cpu_logic};
	$flavor_data{ram} = $info->{memory_total};
	$flavor_data{disk} = 1;
	

	$url .= "/flavors";
	my $get_url = $url."/detail";
	my $flavor_get_data = get_request($token_id,$get_url)->decoded_content;	
    	my $flavor_get_data_hash = decode_json($flavor_get_data)->{flavors};
	
	# can't create the images with overlapping names if use this code	
	foreach my $tmp_flavor_data (@$flavor_get_data_hash){
		if(($tmp_flavor_data->{vcpus} == $flavor_data{vcpus}) && ($tmp_flavor_data->{ram} == $flavor_data{ram})&& ($tmp_flavor_data->{disk} == $flavor_data{disk})){
			$flavor_return_value = $tmp_flavor_data->{id};	
			return $flavor_return_value;
		}
	}

	
	my $tem_vcpus = $flavor_data{vcpus};
	my $tem_ram = $flavor_data{ram};
	my $tem_disk = $flavor_data{disk};

	my $flavor_data = "{\"name\":\"$vmname\",\"ram\":\"$tem_ram\",\"vcpus\":\"$tem_vcpus\",\"disk\":\"$tem_disk\"}";
	my $post_data = "{\"flavor\":$flavor_data}"; 
	my $flavor_post_value = post_request($token_id,$url,$post_data)->decoded_content;	

    	my $flavor_post_data_hash = decode_json($flavor_post_value);
	$flavor_return_value = $flavor_post_data_hash->{flavor}->{id};	
	return $flavor_return_value;
}

sub get_db_user_passwd{
    my $config_file = "/etc/pcenter/cfgloc.mysql";
    my $res = open(my $fh,'<',$config_file);
    if (!$res or !defined($res)){
        pcenter::MsgUtils->log("############### open the $config_file  failed :$!\n", "debug");
    }
    my $host;
    my $db;
    my $username;
    my $password;

    #mysql:dbname=pcenterdb;host=192.168.137.78|pcenteradmin|wang1234
    while(<$fh>){
        $_ =~ /mysql:dbname=(\w+);host=(\w+).(\w+).(\w+).(\w+)\|(\w+)\|(\w+)/;
        $db = $1;
        $host = "$2\.$3\.$4\.$5";
        $username = $6;
        $password = $7;
    }
    return "$host:$db:$username:$password";
}

sub generate_image
{
	my $token = shift;
	my $vmname = shift;
	my $returned_image_id = ();

	my $token_id = $token->{access}->{token}->{id};
	
        #finde url
	my $url;
	my $service_info = $token->{access}->{serviceCatalog};
	foreach my $tmp_value (@$service_info){
		if ($tmp_value->{type} eq "image"){
			$url = $tmp_value->{endpoints}[0]->{adminURL};
			last;
		}
	}
	$url .= "/v2/images";
	# gian the infomation that related to image frome pcenter database based on vmname

	 my $dict = get_db_user_passwd();
	 my ($host,$db,$username,$password) = split(':',$dict);
	 my  $dbd = DBI->connect("DBI:mysql:$db:$host", "$username", "$password");
	 my $pre = $dbd->prepare( qq{SELECT os FROM t_vm where lpar_name="$vmname" ;});
	 $pre->execute();
	 my $info = $pre->fetchrow_hashref();
	 $pre->finish();
	 $dbd->disconnect();

	my $image_name = $info->{os};
	my $get_url = $url."?name=$image_name";
	my $image_get_data = get_request($token_id,$get_url)->decoded_content;	
    	my $image_get_data_hash = decode_json($image_get_data);
	

	# can't create the images with overlapping names if use this code	
        if(($image_get_data_hash->{images}[0]->{name} eq $image_name) && ($image_get_data_hash->{images}[0]->{status} == "active")){
		$returned_image_id = $image_get_data_hash->{images}[0]->{id};	
	}else{
		my $image_name = get_table_value("os","t_vm","lpar_name",$vmname)->{os};
		my $post_data ='{"file_format":"vhd","protected":false,"min_disk":1,"visibility":"public","container_format": "bare", "disk_format": "vhd", "name": "$image_name"}' ;
		$post_data =~ s/^(.*)"(\$image_name)/$1"$image_name/;

		my $image_value = post_request($token_id,$url,$post_data)->decoded_content;	
		# upload image data
		my $put_data = "@/root/$image_name"."vhd";
    		my $image_value_hash = decode_json($image_value);
		my $image_id = $image_value_hash->{id};	
                $returned_image_id = $image_id;
		my $put_url = $url."/$image_id/file";

		open(FD,">/root/$image_name.vhd") or die $!;
		print FD "this is image file";
		close(FD);

		my $tmp_ret_val = put_request($token_id,$put_url,$put_data);	
		my $pcenter_cmd = "rm -rf /root/$image_name";
		my $outref = pcenter::Utils->runcmd("$pcenter_cmd", 0);
	} 	
	return $returned_image_id;
}
sub generate_token
{
	my $parameter = shift;
	my $ua = LWP::UserAgent->new;
	my $version = ();#$parameter->{v};
	my $tenant = $parameter->{t};
	my $username = $parameter->{u};
	my $password = $parameter->{p};

        #Create a config
        my $Config = Config::Tiny->new;
    
        #Open the config
        my $config_path = "/etc/pcenter/openstack.conf";
        $Config = Config::Tiny->read($config_path);
        $Config = Config::Tiny->read($config_path, 'utf8' ); # Neither ':' nor '<:' prefix!
        $Config = Config::Tiny->read($config_path, 'encoding(iso-8859-1)');
    
        #Reading properties
        my $rootproperty = $Config->{_}->{rootproperty};
        my $website = $Config->{section}->{token}; 
	
	my $server_endpoint = "$website";

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(POST => $server_endpoint);
	$req->header('content-type' => 'application/json');
	#$req->header('x-auth-token' => 'kfksj48sdfj4jd9d');

	# add POST data to HTTP request body

	my $auth = "{\"tenantName\": \"$tenant\",\"passwordCredentials\": {\"username\": \"$username\", \"password\": \"$password\"}}";
	my $post_data ="{\"auth\": $auth}";

	$req->content($post_data);

	my $resp = $ua->request($req);
	my $return_value;
	if ($resp->is_success) {
		 my $token_json = $resp->decoded_content;
    		 my $token_hash = decode_json($token_json);
		 $return_value = $token_hash;
	}
	else {
	}
	
	return $return_value;

}

sub get_request
{
	my $token = shift;
	my $url = shift;
	my $ua = LWP::UserAgent->new;
	my $server_endpoint = $url;

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(GET => $server_endpoint);
	$req->header('x-auth-token' => "$token");

	my $resp = $ua->request($req);
	my $return_value;
	if ($resp->is_success) {
		$return_value = $resp;
	}
	else {
		$return_value = "fail !";
	}
	
	return $return_value;
}

sub put_request
{
	my $token = shift;
	my $url = shift;
	my $put_data = shift;
	my $ua = LWP::UserAgent->new;
	my $server_endpoint = $url;

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(PUT => $server_endpoint);
	$req->header('content-type' => 'application/octet-stream');
	$req->header('x-auth-token' => "$token");

	# add POST data to HTTP request body
	$req->content($put_data);

	my $resp = $ua->request($req);
	my $return_value;
	if ($resp->is_success) {
		$return_value = $resp;
	}
	else {
		$return_value = "fail !";
	}
	
	return $return_value;
}

sub post_request
{
	my $token = shift;
	my $url = shift;
	my $post_data = shift;
	my $ua = LWP::UserAgent->new;
	my $server_endpoint = $url;

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(POST => $server_endpoint);
	$req->header('content-type' => 'application/json');
	$req->header('x-auth-token' => "$token");

	# add POST data to HTTP request body
	$req->content($post_data);

	my $resp = $ua->request($req);
	my $return_value;
	if ($resp->is_success) {
		$return_value = $resp;
	}
	else {
		$return_value = "fail !";
	}
	
	return $return_value;
}

1;
