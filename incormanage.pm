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
use JSON;
use Net::CIDR;
use Net::CIDR ':all';
use Config::Tiny;



##############################################
# Globals
##############################################
my %method = (
    incormanage => \&incormanage_parse_args,
    admintoken => \&admintoken_parse_args,
    incortoken => \&incortoken_parse_args,
    incorusers => \&incorusers_parse_args,
    unincormanage => \&unincormanage_parse_args,
);


##########################################################################
# Parse the command line for options and operands
##########################################################################
sub parse_args {

    my $request = shift;
    my $cmd     = $request->{command};

    ###############################
    # Invoke correct parse_args 
    ###############################
    my $result = $method{$cmd}( $request );
    return( $result ); 
}


##########################################################################
# Parse the command line for options and operands
##########################################################################
sub incorusers_parse_args {
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

    if ( !GetOptions( \%opt, qw(V|verbose t=s) )) {
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

##########################################################################
# Parse the command line for options and operands
##########################################################################
sub incortoken_parse_args {
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

    if ( !GetOptions( \%opt, qw(V|verbose u=s p=s t=s ) )) {
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


##########################################################################
# Parse the command line for options and operands
##########################################################################
sub admintoken_parse_args {
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

    if ( !GetOptions( \%opt, qw(V|verbose u=s p=s) )) {
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


##########################################################################
# Parse the command line for options and operands
##########################################################################
sub unincormanage_parse_args {
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

    if ( !GetOptions( \%opt, qw(V|verbose t=s z=s i=s) )) {
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



##########################################################################
# Parse the command line for options and operands
##########################################################################
sub incormanage_parse_args {
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

    if ( !GetOptions( \%opt, qw(V|verbose a=s t=s u=s p=s v=s z=s) )) {
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

BEGIN
{
    my $config_file = "/etc/pcenter/cfgloc.mysql";
    my $res = open(my $fh,'<',$config_file);
    if (!$res or !defined($res)){
        pcenter::MsgUtils->log("############### open the $config_file  failed :$!\n", "debug");
    }
    my $host;
    my $db;
    my $username;
    my $password;

    while(<$fh>){
        $_ =~ /mysql:dbname=(\w+);host=(\w+).(\w+).(\w+).(\w+)\|(\w+)\|(\w+)/;
        $db = $1;
        $host = "$2\.$3\.$4\.$5";
        $username = $6;
        $password = $7;
    }

    $::dbd = DBI->connect("DBI:mysql:$db:$host", "$username", "$password");
}

END
{
	$::dbd->disconnect();
}

sub incorusers
{
    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my $hwtype  = @$exp[2];
    my $opt     = $request->{opt};
    my @values  = ();
    my $Rc = undef;
    my $return_value = ();
    my @vmnames = split(/,/,$opt->{v});

    my $url = gain_conf_value("url","user_list");
    my $token = $opt->{t};
    my $users_hash = get_request($token,$url);
    my $user_list ;

    if(defined ($users_hash->{users})){
	    foreach my $tmp_user_value (@{$users_hash->{users}}){
		    $user_list .= $tmp_user_value->{name}.",";
	    }	
	    $user_list =~ s/^(.*),$/$1/;

	    push @values, ["success","$user_list",0];
    }else{
    	push @values, ["fail","$users_hash",0];
    }


    return( \@values );
}

sub general_tenant_id
{
	my $token = shift;
	my $user_id = shift;
	my $tenant_id;
	my $url = gain_conf_value("url","projects");
	$url =~ s/^(.*)(userid)(.*)$/$1$user_id$3/;	

	my $tenants_hash = get_request($token,$url);
	my $admin_tenant = gain_conf_value("tenant","administrator");
	$tenant_id = @{$tenants_hash->{projects}}[0]->{id};

	return $tenant_id;
}

sub get_tenant_id
{
	my $token = shift;
	my $user_id = shift;
	my $tenant_id ;
	my $url = gain_conf_value("url","projects");
	$url =~ s/^(.*)(userid)(.*)$/$1$user_id$3/;	

	my $tenants_hash = get_request($token,$url);
	my $admin_tenant = gain_conf_value("tenant","administrator");
	if(defined ($tenants_hash->{projects})){
		foreach my $tenants (@{$tenants_hash->{projects}}){
			if($tenants->{name} eq $admin_tenant){
				$tenant_id = $tenants->{id};
				last;
			}
		}

	}else{
		$tenant_id = $admin_tenant;
	}
	return $tenant_id;
}

sub incortoken
{
    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my $hwtype  = @$exp[2];
    my $opt     = $request->{opt};
    my @values  = ();
    my $Rc = undef;
    my $return_value = ();

    my $username = $opt->{u}; 
    my $password = $opt->{p}; 
    my $tenant = $opt->{t};

    my $auth = "{\"tenantName\": \"$tenant\",\"passwordCredentials\": {\"username\": \"$username\", \"password\": \"$password\"}}";
    my $token_info = generate_token($auth);
    if($token_info->{rc}){
    	push @values, ["fail","$token_info->{message}",0];
    	return( \@values );
    }

    my $token = $token_info->{access}->{token}->{id};
    my $tenant_id = $token_info->{access}->{token}->{tenant}->{id};
    push @values, ["success","$token,$tenant_id",0];
	
    return( \@values );
}

sub admintoken
{
	my $request = shift;
	my $hash    = shift;
	my $exp     = shift;
	my $hwtype  = @$exp[2];
	my $opt     = $request->{opt};
	my @values  = ();
	my $Rc = undef;
	my $return_value = ();
	my $is_admin = ();

	my $username = $opt->{u}; 
	my $password = $opt->{p}; 
	#Create a config
	my $Config = Config::Tiny->new;

	#Open the config
	my $config_path = "/etc/pcenter/openstack.conf";
	$Config = Config::Tiny->read($config_path);
	$Config = Config::Tiny->read($config_path, 'utf8' ); # Neither ':' nor '<:' prefix!
		$Config = Config::Tiny->read($config_path, 'encoding(iso-8859-1)');

	#Reading properties
	my $tenant = $Config->{tenant}->{administrator};

	my $auth = "{\"tenantName\": \"$tenant\",\"passwordCredentials\": {\"username\": \"$username\", \"password\": \"$password\"}}";

	my $token_info = generate_token($auth);
	if($token_info->{rc}){
		push @values, ["fail","$token_info->{message}",0];
		return( \@values );
	}

	my $token = $token_info->{access}->{token}->{id};
	my $tenant_id = $token_info->{access}->{token}->{tenant}->{id};
	foreach my $role (@{$token_info->{access}->{user}->{roles}}){
		if($role->{name} eq "admin"){
			$is_admin = 1;
			last;
		}
	}

	if(defined ($is_admin)){
		push @values, ["success","$token,$tenant_id",0];
	}else{
		push @values, ["fail","not administrator",0];
	}


	return( \@values );
}

sub gain_conf_value
{	
	my $section =shift;
	my $service_name = shift;
        #Create a config
        my $Config = Config::Tiny->new;
    
        #Open the config
        my $config_path = "/etc/pcenter/openstack.conf";
        $Config = Config::Tiny->read($config_path);
        $Config = Config::Tiny->read($config_path, 'utf8' ); # Neither ':' nor '<:' prefix!
        $Config = Config::Tiny->read($config_path, 'encoding(iso-8859-1)');
    
        #Reading properties
        my $rootproperty = $Config->{_}->{rootproperty};
        my $website = $Config->{$section}->{$service_name}; 
	
	my $server_endpoint = "$website";
	return $server_endpoint ;
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
    my @vmnames = split(/,/,$opt->{v});

    my $admintoken = $opt->{a};
    my $admintenant = $opt->{t};
    my $usertoken = $opt->{u};
    my $usertenant = $opt->{p};
    my $available_zone = $opt->{z};
    my $token = generate_token($opt);
    my $incor_return ; 
    foreach my $vmname(@vmnames){
=pod
	    my $az_verification = az_verification($available_zone, $admintoken, $admintenant);
	    if ($az_verification->{rc} == 1){
		    push @values,["fail","az_verification $az_verification->{message}",0];
		    return( \@values );
	    }
	    my $az_suf = get_available_zone($vmname,$admintoken, $admintenant);
	    if ($az_suf->{rc} == 1){
		    push @values,["fail","az_suf $az_suf->{message}",0];
		    return( \@values );
	    }
	    $available_zone .= $az_suf->{message};
=cut

	    my $flavor_value = generate_flavor($admintoken,$vmname,$admintenant);
	    if ($flavor_value->{rc} == 1){
		    push @values,["fail","flavor $flavor_value->{message}",0];
		    return( \@values );
	    } 
	    my $flavor_id = $flavor_value->{flavor}->{id};

	    my $image_value = generate_image($admintoken,$vmname);
	    if ($image_value->{rc} == 1){
		    push @values,["fail","flavor $image_value->{message}",0];
		    return( \@values );
	    }
	    my $image_id = $image_value->{id};
	    
	    my @port;
	    my @network_value = generate_network($admintoken,$usertoken,$usertenant,$vmname);
	    foreach my $temp_net_val (@network_value){
		    if (($temp_net_val->{rc} == 1) or ($temp_net_val->{port}->{id} eq "" )){
			    push @values,["fail","network $temp_net_val->{message}",0];
			    return( \@values );
		    }
		   push @port,$temp_net_val->{port}->{id};
	    }
	    my %vm_parameter;
	    $vm_parameter{image_id} = $image_id;
	    $vm_parameter{flavor_id} = $flavor_id;
	    $vm_parameter{available_zone} = $available_zone;
	    $vm_parameter{vm_name} = $vmname;
	    $vm_parameter{vm_ports} = \@port;
	    my $vm_ret_val = create_vm ($usertoken,\%vm_parameter,$usertenant);
	    if ($vm_ret_val->{rc} == 1){
		    push @values,["fail","vm $vm_ret_val->{message}",0];
		    return( \@values );
	    }
	    my $vm_id = $vm_ret_val->{server}->{id};
	
	    my $attach_value = attach_lv($usertoken,$usertenant,$vm_id,$vmname);
	    if ($attach_value->{rc} == 1){
		    push @values,["fail","attach lv: $attach_value->{message}",0];
		    return( \@values );
	    }
	    $incor_return .= "$vmname:$flavor_id:$image_id:$port[0]:$vm_id,";
   } 
    $incor_return =~ s/^(.*),$/$1/; 
    push @values, ["success","$incor_return",0];
    return( \@values );
}

sub get_vm_state
{
	my $usertoken = shift;
	my $usertenant = shift;
	my $vm_id = shift;
    
	my $url = gain_conf_value("url","flavor");
	$url =~ s/^(.*)(tenantid)$/$1$usertenant\/servers\/$vm_id/;	
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $usertoken;
	my $vm_st_response = http_request($req_parameter);
	return $vm_st_response;
}

sub get_lv_info
{
    my $vmname = shift;
    my $sql_statement = "select disk_name,disk_total_size from t_disk where lpar_name=\"$vmname\" and disk_belong_vg!=\"rootvg\";";
    my $disks_info = get_table_values($sql_statement);
    return $disks_info; 
}

sub attach_lv
{
	my $usertoken = shift;
	my $usertenant = shift;
	my $vm_id = shift;
	my $vm_name = shift;
	my $attach_lv_reval;
	my $req_num; 
	while(1){
		my $vm_current_st ;	
		$vm_current_st = get_vm_state($usertoken,$usertenant,$vm_id);
		if($vm_current_st->{rc}){
			return 	$vm_current_st;
		}
		if($vm_current_st->{server}->{status} eq "ACTIVE"){
			my $lv_info = get_lv_info($vm_name); 
			my $url = gain_conf_value("url","flavor");
			my $lv_url = $url;	
			$lv_url =~ s/^(.*)(tenantid)$/$1$usertenant\/os-volumes/;	
			my $req_parameter;
			$req_parameter->{'type'} = "POST";
			$req_parameter->{'address'} = $lv_url;
			$req_parameter->{'token'} = $usertoken;
			foreach my $tmp_lv_info(@$lv_info){
				my $post_data =  "{\"volume\":{\"display_name\":\"$vm_name$tmp_lv_info->{disk_name}\",\"size\":$tmp_lv_info->{disk_total_size}}}";
				$req_parameter->{'data'} = $post_data;
				my $lv_post_value = http_request($req_parameter);
				if($lv_post_value->{rc}){
					$lv_post_value->{message} =~ s/(.*)/create lv: $1/; 	
					return $lv_post_value;
				}
				my $lv_id = $lv_post_value->{volume}->{id};

				my $req_lv_stat_url = $url;
				$req_parameter->{'type'} = "GET";
				$req_lv_stat_url =~ s/^(.*)(tenantid)$/$1$usertenant\/os-volumes\/$lv_id/;	
				$req_parameter->{'address'} = $req_lv_stat_url;
				$req_parameter->{'token'} = $usertoken;
				my $lv_status;
				$lv_status = http_request($req_parameter);
				my $lv_status_num;
				while(1){

					$lv_status = http_request($req_parameter);
					$lv_status_num ++;
					if(($lv_status->{volume}->{status} eq "error") or($lv_status_num > 10)){
						my $lv_status;
						$lv_status->{rc} = 1;
						$lv_status->{message} = "create lv fail";
						return $lv_status;
					}
					if($lv_status->{volume}->{status} eq "available"){
						last;
					}
					sleep(2);
				}
	
				$post_data =  "{\"volumeAttachment\":{\"volumeId\":\"$lv_id\"}}" ;
				my $attach_lv_url = $url;
				$attach_lv_url =~ s/^(.*)(tenantid)$/$1$usertenant\/servers\/$vm_id\/os-volume_attachments/;	
				$req_parameter->{'type'} = "POST";
				$req_parameter->{'address'} = $attach_lv_url;
				$req_parameter->{'data'} = $post_data;
				my $attach_lv_value = http_request($req_parameter);
				if($attach_lv_value->{rc}){
					$attach_lv_value->{message} =~ s/(.*)/attach lv: $1/; 	
					return $attach_lv_value;
				}

			}
			$attach_lv_reval->{rc} = 0;
			$attach_lv_reval->{message} = "atach lv success";

			return $attach_lv_reval;

		}elsif($vm_current_st->{server}->{status} eq "ERROR"){
			$attach_lv_reval->{rc} = 1;
			$attach_lv_reval->{massage} = "create vm fail";
			return $attach_lv_reval;
		}

		sleep(20);
		$req_num ++;
		if($req_num > 5){
			$attach_lv_reval->{rc} = 1;
			$attach_lv_reval->{massage} = "attach lv fail";
			return $attach_lv_reval;
		}
	}
}

sub del_vm_lv
{
	my $usertoken = shift;
	my $usertenant = shift;
	my $vm_id = shift;
	my $vmname;
	my $detach_lv_reval;
	my $url = gain_conf_value("url","flavor");
	my $lv_url = $url;	
	my $vm_detial_url = $url;
	my $lv_uuid = "";
	my @values;
	my $req_parameter;
	my $detach_value;

	$vm_detial_url =~ s/^(.*)(tenantid)$/$1$usertenant\/servers\/$vm_id/;	
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $vm_detial_url;
	$req_parameter->{'token'} = $usertoken;
	my $vm_info = http_request($req_parameter);
	$vmname = $vm_info->{server}->{name};
	if ($vm_info ->{rc} == 1){
		return $vm_info;
	}

	$req_parameter->{'type'} = "DELETE";
	$req_parameter->{'token'} = $usertoken;
        		
	$vmname = "power03";	
	my $sql_statement = "select disk_name,uuid from t_disk where lpar_name=\"$vmname\" and disk_belong_vg!=\"rootvg\";";
	my $disks_info = get_table_values($sql_statement);
	foreach my $tmp_lv_info(@$disks_info){
		$lv_uuid = $tmp_lv_info->{uuid};
		$lv_url =~ s/^(.*)(tenantid)$/$1$usertenant\/servers\/$vm_id\/os-volume_attachments\/$lv_uuid/;	
		$req_parameter->{'address'} = $lv_url;
		my $lv_post_value = http_request($req_parameter);
		if ($lv_post_value->{rc} == 1){
			return $lv_post_value;
		}
		
		my $lv_info_url = $url;
		$lv_info_url =~ s/^(.*)(tenantid)$/$1$usertenant\/os-volumes\/$lv_uuid/;
		$req_parameter->{'type'} = "GET";
		$req_parameter->{'address'} = $lv_info_url;
		$req_parameter->{'token'} = $usertoken;
		my $lv_status_num ;
		while(1){
			my $lv_st_reval = http_request($req_parameter);
			$lv_status_num ++;
			if(($lv_status_num > 10)){
				my $lv_status;
				$lv_status->{rc} = 1;
				$lv_status->{message} = "detach lv fail";
				return $lv_status;
			}
			if($lv_st_reval->{volume}->{status} eq "available"){
				last;
			}
			sleep(5);
		}	
		
		# delete lv 	
		$req_parameter->{'type'} = "DELETE";
		my $rm_lv_return = http_request($req_parameter);
		if($rm_lv_return->{rc}){
			return $rm_lv_return;
		}
	}
	$detach_value->{rc} = 0;
	$detach_value->{message} = "success";

	return $detach_value;
}

sub unincormanage
{
	my $request = shift;
	my $hash    = shift;
	my $exp     = shift;
	my $hwtype  = @$exp[2];
	my $opt     = $request->{opt};
	my @values  = ();
	my $Rc = undef;

	my $token = $opt->{t};
	my $tenantid = $opt->{z};
	my $vmid = $opt->{i};
	my $url = gain_conf_value("url","unincorperate");
	$url =~ s/^(.*)(tenantid)(.*)(vmid)$/$1$tenantid$3$vmid/;	
	my $delete_return_value;
	
	my $del_lv_return = del_vm_lv($token,$tenantid,$vmid); 
	if ($del_lv_return->{rc} == 1){
		push @values,["fail","unincor $del_lv_return->{message}",0];
		return( \@values );
	}

	my $req_parameter;
	$req_parameter->{'type'} = "DELETE";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $token;
	my $delete_return_value = http_request($req_parameter);
	if($delete_return_value->{rc}){
		push @values, ["fail","$delete_return_value->{message}",0];
	}else{
		push @values, ["success","success",0];
	}

	push @values, ["success","success",0];
	return( \@values );
}


sub create_vm
{
	my $token_id= shift;
	my $vm_parameter = shift;
	my $user_tenant = shift;
	my $url = gain_conf_value("url","servers");

	$url =~ s/^(.*)(tenantid)(.*)$/$1$user_tenant$3/;	
	my %flavor_data = {};
	my $vm_return_value = ();
	my $vm_name = $vm_parameter->{vm_name};
	my $image_id = $vm_parameter->{image_id};
	my $flavor_id = $vm_parameter->{flavor_id};
	my $available_zone = $vm_parameter->{available_zone};
	my $vm_ports ;
	foreach my $tmp_port_value (@{$vm_parameter->{vm_ports}}){
		$vm_ports .= "{\"port\":\"$tmp_port_value\"},";
	}	
	$vm_ports =~ s/^(.*),$/$1/;

	#my $post_data = "{\"server\":{\"name\": \"$vm_name\",\"imageRef\": \"$image_id\",\"availability_zone\":\"$available_zone\",\"flavorRef\": \"$flavor_id\",\"networks\":[$vm_ports]}}";
	my $post_data = "{\"server\":{\"name\": \"$vm_name\",\"imageRef\": \"$image_id\",\"flavorRef\": \"$flavor_id\",\"networks\":[$vm_ports]}}";
	my $req_parameter;
	$req_parameter->{'type'} = "POST";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $token_id;
	$req_parameter->{'data'} = $post_data;
	my $vm_post_value = http_request($req_parameter);
	if($vm_post_value->{rc}){
		return $vm_post_value;
	}
     	$vm_return_value->{rc} = 0;
     	$vm_return_value->{server}->{id} = $vm_post_value->{server}->{id} ;
	return $vm_return_value;
}

sub ipsring2int
{
        my $ip = shift;
        $ip =~  /(\d+).(\d+).(\d+).(\d+)/;
        my $int_ip =  $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4;
        return $int_ip;
}

sub get_subnet_id
{
	my $token_id = shift;
	my $url	= shift;
	my $vm_ip = shift;
	my $vm_mask = shift;
	my $gateway_ip = shift;
	my $vmname = shift;
	my $network_return_value = shift;
	my $usertenant = shift;
	
	my $cidr;
	$cidr = Net::CIDR::addrandmask2cidr($vm_ip, $vm_mask);
	
	my $subnet_return_value = ();

	my $subnet_url = $url."v2.0/subnets";
	#my $subnet_get_data_hash = get_request($token_id,$subnet_url);	
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $subnet_url;
	$req_parameter->{'token'} = $token_id;
	my $subnet_get_data_hash = http_request($req_parameter);
	if($subnet_get_data_hash->{rc}){
		return $subnet_get_data_hash ;
	}
	 
	my $create_subnet_flag = 0;
	foreach my $tmp_subnet_value (@{$subnet_get_data_hash->{subnets}}){
		#if(($tmp_subnet_value->{'network_id'} eq $network_return_value) && ($tmp_subnet_value->{'cidr'} eq $cidr)){
		if( ($tmp_subnet_value->{'cidr'} eq $cidr)){
			my $allocation_pools = $tmp_subnet_value->{'allocation_pools'};
			foreach my $temp_pools (@$allocation_pools){
				if((ipsring2int($vm_ip) >= ipsring2int($temp_pools->{'start'})) && (ipsring2int($vm_ip) <= ipsring2int($temp_pools->{'end'}))){
					$create_subnet_flag = 5;
					$subnet_return_value->{subnet}->{id} = $tmp_subnet_value->{'id'};
					$subnet_return_value->{rc} = 0;
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
			$start_num =~ s/(\d+).(\d+).(\d+).(\d+)/$4/;
			$end_num = $start_num; 
		}
		my $start_ip =$vm_ip;
		$start_ip =~ s/(\d+).(\d+).(\d+).(\d+)./$1.$2.$3.$start_num/;
		my $end_ip =$vm_ip;
		$end_ip =~ s/(\d+).(\d+).(\d+).(\d+)./$1.$2.$3.$end_num/;

		my $create_subnet_parameter = "{\"name\": \"$vmname\",\"enable_dhcp\": true,
		   \"network_id\":\"$network_return_value\",\"ip_version\":4,\"cidr\":\"$cidr\",
		   \"gateway_ip\":null,\"allocation_pools\":[{\"start\":\"$start_ip\",\"end\":\"$end_ip\"}]}";
		my $post_data = "{\"subnet\":$create_subnet_parameter}";

		$req_parameter->{'type'} = "POST";
		$req_parameter->{'address'} = $subnet_url;
		$req_parameter->{'token'} = $token_id;
		$req_parameter->{'data'} = $post_data;
		my $subnet_post_value = http_request($req_parameter);

		if($subnet_post_value->{rc}){
			return $subnet_post_value;
		}
		$subnet_return_value->{subnet}->{id} = $subnet_post_value->{subnet}->{id};	
		$subnet_return_value->{rc} = 0;

	}

	return $subnet_return_value;
}

sub get_net_id
{
	my $token_id = shift;
	my $url	= shift;
	my $vlan_id = shift;
	my $vmname = shift;
	my $usertenant = shift;
	my $network_url = $url."v2.0/networks";
	my $network_return_value ;

	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $network_url;
	$req_parameter->{'token'} = $token_id;
	my $net_response = http_request($req_parameter);
	if($net_response->{rc} ){
		return $net_response;
	}else{
		my $create_net_flag = ();
		foreach my $tmp_network_value (@{$net_response->{networks}}){
			if ($tmp_network_value->{'provider:segmentation_id'} eq $vlan_id){
				$network_return_value->{id} = $tmp_network_value->{'id'};	
				$network_return_value->{rc} = 0;	
				$create_net_flag = 1;
				last;
			}
		}

		unless($create_net_flag){
			my $create_network_parameter = "{\"name\": \"$vmname\",\"tenant_id\":\"$usertenant\",\"admin_state_up\": true,\"provider:network_type\":\"vxlan\",\"provider:segmentation_id\":\"$vlan_id\"}";
			my $post_data = "{\"network\":$create_network_parameter}";

			$req_parameter->{'type'} = "POST";
			$req_parameter->{'address'} = $network_url;
			$req_parameter->{'token'} = $token_id;
			$req_parameter->{'data'} = $post_data;
			my $net_post_value = http_request($req_parameter);
			if($net_post_value->{rc}){
				return $net_post_value;
			}else{
				$network_return_value->{rc} = 0;	
				$network_return_value->{id} = $net_post_value->{network}->{id};
			}
		}

		return $network_return_value;

	}

}

sub get_port_id
{
	my $token_id = shift;
	my $url	= shift;
	my $port_ip = shift;
	my $network_return_value = shift;
	my $subnet_return_value = shift;
	my $vmname = shift;
	my $usertenant = shift;

	my $port_return_value = ();
	my $port_url = $url."v2.0/ports";

	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $port_url;
	$req_parameter->{'token'} = $token_id;
	my $port_get_data_hash = http_request($req_parameter);
	if($port_get_data_hash->{rc}){
		return $port_get_data_hash ;
	}

	my $create_port_flag = ();
	my $tmp_ports = $port_get_data_hash->{ports};
	foreach my $tmp_port_value (@{$port_get_data_hash->{ports}}){
		if (($tmp_port_value->{'network_id'} eq $network_return_value) ){
			my $tmp_ips_hash = $tmp_port_value->{fixed_ips};	
			foreach my $temp_fixed_ips (@$tmp_ips_hash){
				if($temp_fixed_ips->{'ip_address'} eq $port_ip ){
					$port_return_value->{port}->{id} = $tmp_port_value->{'id'};	
					$port_return_value->{rc} = 0;
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
		my $create_ports_parameter = "{\"name\": \"$vmname\",\"tenant_id\":\"$usertenant\",\"admin_state_up\": true,
		   \"network_id\":\"$network_return_value\",\"binding:vnic_type\":\"normal\",
		   \"fixed_ips\":[{\"subnet_id\":\"$subnet_return_value\",\"ip_address\":\"$port_ip\"}]}";
		my $post_data = "{\"port\":$create_ports_parameter}";

		$req_parameter->{'type'} = "POST";
		$req_parameter->{'address'} = $port_url;
		$req_parameter->{'token'} = $token_id;
		$req_parameter->{'data'} = $post_data;
		my $ports_post_value = http_request($req_parameter);	
		if($ports_post_value->{rc}){
			return $ports_post_value;
		}	
		$port_return_value->{port}->{id} = $ports_post_value->{port}->{id};		
		$port_return_value->{rc} = 0;

	}
	return $port_return_value ;
}

sub generate_network
{
	my $admintoken = shift;
	my $usertoken = shift;
	my $usertenant = shift;
	my $vmname = shift;
	my @return_ports = ();

	my $url = gain_conf_value("url","network");

	#create network
	my $network_return_value = ();
	my $network_url = $url."v2.0/networks";
	my @return_values;
    	my $sql_statement = "SELECT eth FROM t_vlan WHERE lpar_name = \"$vmname\";"; 
	my $eths = get_table_values($sql_statement);
	foreach my $tmp_eth (@$eths){
		my $net_id;
		my $subnet_id;
		my $port_id;
		my $sql_statement = "SELECT vlan FROM t_vlan WHERE lpar_name = \"$vmname\" AND eth = \"$tmp_eth->{eth}\";";
		my $eth_vlan = get_table_value($sql_statement);
			
		my $sql_statement = "SELECT ip FROM t_network WHERE lpar_name = \"$vmname\" AND eth = \"$tmp_eth->{eth}\";";
		my $eth_ip = get_table_value($sql_statement);
		
		my $sql_statement = "SELECT mask FROM t_network WHERE lpar_name = \"$vmname\" AND eth = \"$tmp_eth->{eth}\";";
		my $eth_mask = get_table_value($sql_statement);
		
		my $sql_statement = "SELECT gateway FROM t_network WHERE lpar_name = \"$vmname\" AND eth = \"$tmp_eth->{eth}\";";
		my $eth_gateway = get_table_value($sql_statement);


		my $net_value = get_net_id($admintoken,$url,$eth_vlan->{'vlan'},$vmname,$usertenant);  
		if($net_value->{rc}){
			return	$net_value;
		}else{
			$net_id = $net_value->{id};	
		}
		my $subnet_value = get_subnet_id($admintoken,$url,$eth_ip->{'ip'},$eth_mask->{'mask'},$eth_gateway->{'gateway'},$vmname,$net_id);  

		if($subnet_value->{rc}){
			return	$subnet_value;
		}else{
			$subnet_id = $subnet_value->{subnet}->{id};	
		}
		
		my $port_value = get_port_id($admintoken,$url,$eth_ip->{'ip'},$net_id,$subnet_id,$vmname,$usertenant,$usertenant);
		if($port_value->{rc}){
			return	$port_value;
		}else{
			$port_id->{port}->{id} = $port_value->{port}->{id};	
			$port_id->{rc} = 0;	
		}

		push @return_ports,$port_id;	
	}
	return  @return_ports;	
}

sub get_table_values
{

	my $sql_statement = shift;
	my  $dbd = $::dbd;
	my $pre = $dbd->prepare( qq{$sql_statement});
	$pre->execute();
	my @return_value;
	while (my $tmp_value = $pre->fetchrow_hashref()){
		push @return_value,$tmp_value;
	}
	$pre->finish();
	return \@return_value;
	
}

sub get_table_value
{
	my $sql_statement = shift;
	my  $dbd = $::dbd;
	my $pre = $dbd->prepare( qq{$sql_statement});
	$pre->execute();
	my $return_value = $pre->fetchrow_hashref();
	$pre->finish();
	return $return_value;
	
} 

sub generate_flavor
{
	my $token_id = shift;
	my $vmname = shift;
	my $admin_tenant = shift;
	my $url = gain_conf_value("url","flavor");
	$url =~ s/^(.*)(tenantid)$/$1$admin_tenant/;	
	my %flavor_data = {};
	my $flavor_return_value = ();
	
	$flavor_data{name} = $vmname;
	$flavor_data{vcpus} = ();
	$flavor_data{ram} = ();
	$flavor_data{disk} = ();

	my  $dbd = $::dbd;
	my $pre = $dbd->prepare( qq{SELECT memory_total,cpu_logic  FROM t_vm where lpar_name="$vmname" ;});
	$pre->execute();
	my $info = $pre->fetchrow_hashref();
	$pre->finish();

	$flavor_data{vcpus} = $info->{cpu_logic};
	$flavor_data{ram} = $info->{memory_total};
	$flavor_data{disk} = 1;

	$url .= "/flavors";
	my $get_url = $url."/detail";
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $get_url;
	$req_parameter->{'token'} = $token_id;
	my $flavor_response = http_request($req_parameter);

	if($flavor_response->{rc}){
		return $flavor_response ;
	}else{
		foreach my $tmp_flavor_data (@{$flavor_response->{flavors}}){

			if(($tmp_flavor_data->{vcpus} == $flavor_data{vcpus}) && ($tmp_flavor_data->{ram} == $flavor_data{ram})&& ($tmp_flavor_data->{disk} == $flavor_data{disk})){
				my $flavor_id;
				$flavor_id->{flavor}->{id} = $tmp_flavor_data->{id};
				$flavor_id->{rc} = 0;
				return $flavor_id;
			}   
		}

		my $tem_vcpus = $flavor_data{vcpus};
		my $tem_ram = $flavor_data{ram};
		my $tem_disk = $flavor_data{disk};
		my $flavor_data = "{\"name\":\"$vmname\",\"ram\":\"$tem_ram\",\"vcpus\":\"$tem_vcpus\",\"disk\":\"$tem_disk\"}";
		my $post_data = "{\"flavor\":$flavor_data}"; 
		$req_parameter->{'type'} = "POST";
		$req_parameter->{'address'} = $url;
		$req_parameter->{'token'} = $token_id;
		$req_parameter->{'data'} = $post_data;
		my $flavor_post_value = http_request($req_parameter);
		return 	$flavor_post_value;

	} 	
}

sub generate_image
{
	my $token_id = shift;
	my $vmname = shift;
	my $returned_image_id;

	#finde url
	my $url = gain_conf_value("url","image");
	my $create_image_flag;

	# gian the infomation that related to image frome pcenter database based on vmname

	my $sql_statement = "SELECT os FROM t_vm WHERE lpar_name = \"$vmname\"";
	my $image_name = get_table_value($sql_statement)->{os};
	my $get_url = $url."?name=$image_name";
	my $req_parameter; 
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $get_url;
	$req_parameter->{'token'} = $token_id;
	my $image_response = http_request($req_parameter);

	if($image_response->{rc}){
		return $image_response ;
	}else{
			foreach my $tmp_image_value (@{$image_response->{images}}){
				if(($tmp_image_value->{status} eq "active")){
					$returned_image_id->{id} = $tmp_image_value->{id};
					$returned_image_id->{rc} = 0;
					return $returned_image_id;
				}	

			}	

			my $post_data ='{"file_format":"vhd","protected":false,"min_disk":1,"visibility":"public","container_format": "bare", "disk_format": "vhd", "name": "$image_name"}' ;
			$post_data =~ s/^(.*)"(\$image_name)/$1"$image_name/;

			$req_parameter->{'type'} = "POST";
			$req_parameter->{'address'} = $get_url;
			$req_parameter->{'token'} = $token_id;
			$req_parameter->{'data'} = $post_data;
			my $image_value = http_request($req_parameter);
			if($image_value->{rc}){
				return $image_value;
			}else{
				$returned_image_id->{id}  = $image_value->{id};	
				my $put_data = "@/root/$image_name".".vhd";
				my $image_id = $image_value->{id};	
				my $put_url = $url."/$image_id/file";

				open(FD,">/root/$image_name.vhd") or die $!;
				print FD "this is image file";
				close(FD);

				$req_parameter->{'type'} = "PUT";
				$req_parameter->{'address'} = $put_url;
				$req_parameter->{'token'} = $token_id;
				$req_parameter->{'data'} = $put_data;

				my $upload_image_value = http_request($req_parameter);
				if($upload_image_value->{rc}){
					return $upload_image_value;
				}else{
					
					$returned_image_id->{rc}  = 0;	
					my $pcenter_cmd = "rm -rf /root/$image_name.vhd";
					my $outref = pcenter::Utils->runcmd("$pcenter_cmd", 0);
					
					$returned_image_id->{rc} = 0;
					return $returned_image_id;
				}

			}
	}
}

sub generate_token
{
	my $auth = shift;
	my $post_data ="{\"auth\": $auth}";
	my $url = gain_conf_value("url","token");
	my $req_parameter;
	$req_parameter->{'type'} = "POST";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'data'} = $post_data;

	my $token_return_value = http_request($req_parameter);
	
	return $token_return_value;
}

sub http_request
{
	my $req_parameter = shift; 
	my $req_return;
	my $ua = LWP::UserAgent->new;

	my $server_endpoint = $req_parameter->{'address'};
	my $req = HTTP::Request->new($req_parameter->{'type'} => $server_endpoint);
	if($req_parameter->{'type'} =~ /PUT/){
		$req->header('content-type' => 'application/octet-stream');
	}else{
		$req->header('content-type' => 'application/json');
	}
	$req->header('x-auth-token' => $req_parameter->{'token'});

	$req->content($req_parameter->{'data'});

	my $resp = $ua->request($req);
	if ($resp->is_success) {
		my $message;
		$message->{rc} = 0;
		if($req_parameter->{'type'} =~ /GET|POST/){
			$message = decode_json($resp->decoded_content);
		}else{
			$message->{message} = "success" ;
		}
		$req_return = $message;
	}else {
		$req_return->{rc} = 1;	
		$req_return->{code} = $resp->code;	
		$req_return->{message} = $resp->message;	
	}
	return $req_return;
}

sub get_available_zone
{
	my $vm_name = shift;
	my $admintoken = shift;
	my $admintenant = shift;

	my $sql_statement = "SELECT parent FROM ppc  WHERE node = \"$vm_name\";";
	my $server_name = get_table_value($sql_statement)->{parent};

	my $url = gain_conf_value("url","flavor");
	$url =~ s/^(.*)(tenantid)$/$1$admintenant\/os-hypervisors/;	
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $admintoken;
	my $hypervisor_list = http_request($req_parameter);
	if($hypervisor_list->{rc}){
		return  $hypervisor_list ;
	}
	my $hypervisor_id;
	foreach my $tmp_hypervisor (@{$hypervisor_list->{hypervisors}}){
		if($tmp_hypervisor->{'hypervisor_hostname'} eq $server_name){
			$hypervisor_id = $tmp_hypervisor->{id};
			last;
		}
	}
	 
	$url .="/$hypervisor_id";
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $admintoken;
	my $hypervisor_detail = http_request($req_parameter);
	if($hypervisor_detail->{rc}){
		return  $hypervisor_detail ;
	}

	my $host_name = $hypervisor_detail->{hypervisor}->{service}->{host};
	my $az_revalue;
	$az_revalue->{rc} = 0;
	$az_revalue->{message} = "\:$host_name\:$server_name";
	return $az_revalue;
}

sub az_verification
{
	my $available_zone = shift;
	my $admintoken = shift;
	my $admintenant = shift;
	my $return_val;

	my $url = gain_conf_value("url","flavor");
	$url =~ s/^(.*)(tenantid)$/$1$admintenant\/os-availability-zone/;	
	my $req_parameter;
	$req_parameter->{'type'} = "GET";
	$req_parameter->{'address'} = $url;
	$req_parameter->{'token'} = $admintoken;
	my $availability_zone_list = http_request($req_parameter);
	if($availability_zone_list->{rc}){
		return  $availability_zone_list ;
	}
	$return_val->{rc} = 1;
	foreach my $tmp_availability_zone (@{$availability_zone_list->{availabilityZoneInfo}}){
		#if(($tmp_availability_zone->{zoneName} eq $available_zone) and ($tmp_availability_zone->{zoneName}->{zoneState}->{available})){
		if(($tmp_availability_zone->{zoneName}->{zoneState}->{available})){
			$return_val->{rc} = 0;
			last;
		}
	}
	if($return_val->{rc}){
		$return_val->{message} = " available zone disabled";
	}	
	return $return_val;
}

1;
