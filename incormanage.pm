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

    if ( !GetOptions( \%opt, qw(V|verbose t=s u=s p=s i=s o=s v=s) )) {
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
	    my $image_value = generate_image($token,$vmname);#"1c153881-9e86-4b50-929d-dbf01878333b";
	    my $flavor_value = generate_flavor($token,$vmname);

	    my %vm_parameter = {};
	    $vm_parameter{image_id} = $image_value;
	    $vm_parameter{flavor_id} = $flavor_value;
	    $vm_parameter{vm_name} = $vmname;
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
	
=pod
    	pcenter::MsgUtils->log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>".Dumper($vm_parameter), "info");
	# can't create the images with overlapping names if use this code	
	# '{"server": {"name": "api_vm","imageRef": "1c153881-9e86-4b50-929d-dbf01878333b","flavorRef": "1"}}'

	my $post_data = 
	my $vm_post_value = post_request($token_id,$url,$post_data)->decoded_content;	
    	my $vm_post_data_hash = decode_json($vm_post_value);
	$vm_return_value = $vm_post_data_hash->{server}->{name};	
=cut

=pod	
	my $credentials = "{\"username\": \"$username\", \"password\": \"$password\"}";
	my $auth = "{\"tenantName\": \"$tenant\",\"passwordCredentials\": $credentials}";
	my $post_data ="{\"auth\": $auth}";
	return $vm_return_value;
=cut
	my $vm_name = $vm_parameter->{vm_name};
	my $image_id = $vm_parameter->{image_id};
	my $flavor_id = $vm_parameter->{flavor_id};
	my $create_vm_parameter = "{\"name\": \"$vm_name\",\"imageRef\": \"$image_id\",\"flavorRef\": \"$flavor_id\"}";
	my $post_data = "{\"server\":$create_vm_parameter}";

    	pcenter::MsgUtils->log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>".Dumper($url), "info");
    	pcenter::MsgUtils->log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>".Dumper($post_data), "info");
	my $vm_post_value = post_request($token_id,$url,$post_data)->decoded_content;	
    	my $vm_post_data_hash = decode_json($vm_post_value);
    	pcenter::MsgUtils->log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>".Dumper($vm_post_data_hash), "info");
	$vm_return_value = $vm_post_data_hash->{server}->{name};	
	return $vm_return_value;
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

	
	$flavor_data{name} = "liutest";
	$flavor_data{vcpus} = 1;
	$flavor_data{ram} = 128;
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

	#gian the infomation that related to flavor frome pcenter database based on vmname
	#my $post_data =  '{"flavor":{"name":"12169","ram":"1024","vcpus":"1","disk":"20"}}' ;
	my $post_data = '{"flavor":{"name":"liutest","ram":"128","vcpus":"1","disk":"1"}}'; 
	my $flavor_post_value = post_request($token_id,$url,$post_data)->decoded_content;	

    	my $flavor_post_data_hash = decode_json($flavor_post_value);
	$flavor_return_value = $flavor_post_data_hash->{flavor}->{id};	
	return $flavor_return_value;
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
	my $image_name = "aix7.1";
	my $get_url = $url."?name=$image_name";
	my $image_get_data = get_request($token_id,$get_url)->decoded_content;	
    	my $image_get_data_hash = decode_json($image_get_data);
	
	# can't create the images with overlapping names if use this code	
        if(($image_get_data_hash->{images}[0]->{name} eq $image_name) && ($image_get_data_hash->{images}[0]->{status} == "active")){
		$returned_image_id = $image_get_data_hash->{images}[0]->{id};	
	}else{
		my $post_data = "{\"container_format\": \"bare\", \"disk_format\": \"raw\", \"name\": \"$image_name\"}" ;
		my $image_value = post_request($token_id,$url,$post_data)->decoded_content;	
		# upload image data
		my $put_data = "@/root/$image_name";
    		my $image_value_hash = decode_json($image_value);
		my $image_id = $image_value_hash->{id};	
                $returned_image_id = $image_id;
	#	my $put_url = $url."/$image_id/file";
		my $put_url = $url."/root/cirros-0.3.4-x86_64-disk.img";

		open(FD,">/root/$image_name") or die $!;
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
	my $ip = $parameter->{i};
	my $port = $parameter->{o};
	my $version = ();#$parameter->{v};
	my $tenant = $parameter->{t};
	my $username = $parameter->{u};
	my $password = $parameter->{p};
	
	# get version
	my $server_endpoint = "http://$ip:$port/";
	my $req = HTTP::Request->new(GET => $server_endpoint);
	$req->header('content-type' => 'application/json');
	my $tmp_ua = LWP::UserAgent->new;
	my $tmp_resp = $tmp_ua->request($req)->decoded_content;
    	my $versiondata_hash = decode_json($tmp_resp);
	$version = $versiondata_hash->{versions}->{values}[0]->{id}; 	
	$version = "v2.0";
	
	$server_endpoint = "http://$ip:$port/$version/tokens";

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(POST => $server_endpoint);
	$req->header('content-type' => 'application/json');
	#$req->header('x-auth-token' => 'kfksj48sdfj4jd9d');

	# add POST data to HTTP request body

	my $credentials = "{\"username\": \"$username\", \"password\": \"$password\"}";
	my $auth = "{\"tenantName\": \"$tenant\",\"passwordCredentials\": $credentials}";
	my $post_data ="{\"auth\": $auth}";

	$req->content($post_data);

	my $resp = $ua->request($req);
	my $return_value;
	if ($resp->is_success) {
		 my $token_json = $resp->decoded_content;
    		 my $token_hash = decode_json($token_json);
		 #$return_value = $token_hash->{access}->{token}->{id};
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
