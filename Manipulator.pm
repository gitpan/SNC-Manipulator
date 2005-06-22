# SNC::Manipulator
#
# Copyright (c) 2004-2005 Charles Morris
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package SNC::Manipulator;

BEGIN {
  use HTTP::Request::Common;
  use LWP::UserAgent;
  $VERSION = '0.10a';
}

#---------- Constructor ----------#
sub new {
  my ($pkg, $SNCip, $SNCport) = @_;
  my ($ip, $port);

  my $instance = bless( {}, $pkg );

  if ($SNCport) { $port = $SNCport; } else { $port = 80; }
  if ($SNCip)
  {
    $ip = $SNCip;
  }
  else
  {
    print STDERR "No IP was given.";
    $ip = "127.0.0.1";
  }

  $instance{ip} = $ip;
  $instance{port} = $port;
  $instance{url} = 'http://' . $ip . ':' . $port;
  $instance{rawurl} = $ip . ':' . $port;
  $instance{delay} = 500; #ms delay for things like move or zoom
  $instance{authzone} = 'Sony Network Camera SNC-RZ30';

  $instance{UserAgent} = new LWP::UserAgent;

return $instance;
}

##########################
#--- object functions ---#

# setDelay()
# sets the millisecond delay between commands.
sub setDelay {
  my ($instance, $delay) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  $instance{delay} = $delay;

return $instance;
}

###########################
#--- inquiry functions ---#

sub inquiry()
{
  my ($instance, $inqjs) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  my (%ret);

  foreach my $line ( split(/\n/, &sendRequest($instance, 'inquiry', $inqjs)) )
  {
    my @fields = split(/\s+/, $line, 2);
    if ( $fields[0] eq 'var' )
    {
      my ($key, $encap_val) = split(/=/, $fields[1]);

      $val = $encap_val; #change, if needed
#      my ($val) = split(/\"/, $encap_val); 

      $ret{$key} = $val;
      $instance{$inqjs}{$key} = $val;
	#this is like $instance{sysinfo}{TitleBar} = "Problem Solving Lab";
    }
  }

return %ret;
}

############################
#--- movement functions ---#

# move()
# moves teh camrea.
sub move {
  my ($instance, $moveinst) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  $moveinst = substr($moveinst, 0, 1);

  if ( $moveinst =~ /U/i )
  {
    &sendRequest($instance, 'visca', '8101060103030302FF');
    &customDelay($instance);
    &stop($instance);
  }
  elsif ( $moveinst =~ /D/i )
  {
    &sendRequest($instance, 'visca', '8101060103030301FF');
    &customDelay($instance);
    &stop($instance);
  }
  elsif ( $moveinst =~ /L/i )
  {
    &sendRequest($instance, 'visca', '8101060103030203FF');
    &customDelay($instance);
    &stop($instance);
  }
  elsif ( $moveinst =~ /R/i )
  {
    &sendRequest($instance, 'visca', '8101060103030103FF');
    &customDelay($instance);
    &stop($instance);
  }
  elsif ( $moveinst =~ /H/i )
  {
    &sendRequest($instance, 'visca', '81010604FF');
  }
  elsif ( $moveinst =~ /I/i )
  {
    &sendRequest($instance, 'visca', '8101040724FF');
    &customDelay($instance);
    &stop($instance);
  }
  elsif ( $moveinst =~ /O/i )
  {
    &sendRequest($instance, 'visca', '8101040734FF');
    &customDelay($instance);
    &stop($instance);
  }
}

# moveDirectPT()
# moves camera by direct Pan/Tilt data
sub moveDirectPT {
  my ($instance, $x, $y) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  if ( $x > 640 || $x < 0 || $y > 480 || $y < 0)
  {
    print "$x,$y needs to be inside 640x480 viewspace\n";
    return undef;
  }

  &sendRequest($instance, 'directpt', $x . ',' . $y);
}

#only in >v1.10
sub moveRelative {
  my ($instance, $moveDirection, $movePercentage) = @_;

  print "$moveDirection : $movePercentage\n";

  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  #for all those wondering, the $AABB variable refrences the tech documents

  if ( $moveDirection eq 'SOUTHWEST' || $moveDirection eq 'SW' ) { $AABB = '01'; }
  elsif ( $moveDirection eq 'SOUTH' || $moveDirection eq 'S' ) { $AABB = '02'; }
  elsif ( $moveDirection eq 'SOUTHEAST' || $moveDirection eq 'SE' ) { $AABB = '03'; }
  elsif ( $moveDirection eq 'WEST' || $moveDirection eq 'W' ) { $AABB = '04'; }
  elsif ( $moveDirection eq 'EAST' || $moveDirection eq 'E' ) { $AABB = '06'; }
  elsif ( $moveDirection eq 'NORTHWEST' || $moveDirection eq 'NW' ) { $AABB = '07'; }
  elsif ( $moveDirection eq 'NORTH' || $moveDirection eq 'N' ) { $AABB = '08'; }
  elsif ( $moveDirection eq 'NORTHEAST' || $moveDirection eq 'NE' ) { $AABB = '09'; }
  else
  {
    print STDERR "$moveDirection is not a valid compass direction.\n";
    print STDERR "can take full or abbreviated directions.\n";
    return undef;
  }

  if ( $movePercentage eq '10' ) { $AABB = '01'; }
  elsif ( $movePercentage eq '15' ) { $AABB = '02'; }
  elsif ( $movePercentage eq '20' ) { $AABB = '03'; }
  elsif ( $movePercentage eq '25' ) { $AABB = '04'; }
  elsif ( $movePercentage eq '30' ) { $AABB = '05'; }
  elsif ( $movePercentage eq '40' ) { $AABB = '06'; }
  elsif ( $movePercentage eq '50' ) { $AABB = '07'; }
  elsif ( $movePercentage eq '66.7' ) { $AABB = '08'; }
  elsif ( $movePercentage eq '83.3' ) { $AABB = '08'; }
  elsif ( $movePercentage eq '100' ) { $AABB = '04'; }
  else
  {
    print STDERR "$movePercentage is not a valid relative move percentage..\n";
    print STDERR "try: 10,15,20,25,30,40,50,66.7,83.3, or 100.\n";
    return undef;
  }

  &sendRequest( $instance, 'relative', $AABB );

return undef;
}

# moveToPreset()
# this function causes the camera to reset to one of its programmed presets.
sub moveToPreset {
  my ($instance, $preset) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__); 
  if ( length($preset) < 2 ) { $preset = '0' . $preset; } #buffer preset if needed
  &sendRequest( $instance, 'visca', '8101043F02' . $preset . 'FF');
					#8101043F0201FF
return $instance;
}

sub stop {
  my ($instance) = shift;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
  &sendRequest( $instance, 'visca', '8101060103030303FF' );
return $instance;
}

# rawVISCA()
# for use by people who know how to build a VISCA statement.
sub rawVISCA
{
  my ($instance, $visca) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
  &sendRequest($instance, 'visca', $visca);
}

###########################
#--- capture functions ---#

sub captureToFile()
{
  my ($instance, $file) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  #$instance{url} . '/oneshotimage.jpg'; #into file $file
}



#########################
#--- other functions ---#

# setLogin()
# simply username & pass to bypass the password protection on some cameras
sub setLogin
{
  my ($instance, $username, $password) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  $instance{username} = $username;
  $instance{password} = $password;

  #this is an OO method ( called after new() ) so we know all these vars are set.
  $instance{UserAgent}->credentials(
			$instance{rawurl},
			$instance{authzone},
			$instance{username},
			$instance{password}
			);
}

# sendRequest() is used to make the other functions look alot simpler and make the module smaller.
# it simply formats and sends the http request to the camera.
sub sendRequest {
  my ($instance, $type, $code) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

#  warn "$type : $code\n";

  if ( $type eq 'visca' )
  {
    my $formurl = $instance{url} . '/command/visca-ptzf.cgi'; #v1.09 or lower
    my $req = HTTP::Request->new(GET => $formurl . '?visca=' . $code);
    return $instance{UserAgent}->request($req)->as_string();
  }
  elsif( $type eq 'directpt' )
  {
    my $formurl = $instance{url} . '/command/directpt.cgi'; #v1.09 or lower
    my $req = HTTP::Request->new(GET => $formurl . '?visca=' . $code);
    return $instance{UserAgent}->request($req)->as_string();
  }
  elsif( $type eq 'relative' )
  {						#or maybe just pztf.cgi
    my $formurl = $instance{url} . '/command/visca-pztf.cgi'; #v1.10 or higher
    my $req = HTTP::Request->new(GET => $formurl . '?relative=' . $code);
    return $instance{UserAgent}->request($req)->as_string();
  }
  elsif( $type eq 'inquiry' )
  {
    my $formurl = $instance{url} . '/command/inquiry.cgi'; #v1.10 or higher
    my $req = HTTP::Request->new(GET => $formurl . '?inqjs=' . $code);
    print "$formurl" . '?inqjs=' . $code . "\n";
    return $instance{UserAgent}->request($req)->as_string();
  }
}

sub customDelay()
{
  my ($instance) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
  sleep 0.001 * $instance{delay}; #do my millisecond delay for (pseudo)precise movements
}

1;

__END__

=head1 NAME

    SNC::Manipulator - Manipulate and Configure Sony SNC-RZ30N networked cameras.

=head1 SYNOPSIS

      use SNC::Manipulator;  

      $SNCcamera = new SNC::Manipulator( "http://192.168.99.4" );

      #Or to use a custom port (2024) call this
      $SNCcamera = new SNC::Manipulator( "http://192.168.99.4", "2024" );

      $SNCcamera->setLogin( 'admin', 'pass' );  #lvl 4

      $SNCcamera->moveToPreset( 0 );
      $SNCcamera->move( "left" );
      $SNCcamera->move( "right" );
      $SNCcamera->move( "up" );
      $SNCcamera->move( "down" );

=head1 DESCRIPTION

    SNC::Manipulator provides a perl interface to all the functions
    available through Sony's control software (and more) on SNC-RZ30N webcams.

=head1 USAGE

    new()
      Constructor.
      Returns new instance of SNC::Manipulator.


    setDelay( $delay )
      parameters:
        $delay, time in milliseconds.

      sets delay between requests in some functions; an example of this is in move().
      the default delay is 500.


    inquiry( $inqjs )
      parameters:
        $inqjs, string passed to inquiry function

      Gets data from camera; and structures inside instance like this:
      $instance{sysinfo}{TitleBar} = "Name of Room";

      Returns hash structured like %h{TitleBar} = "Name of Room";


    move( $moveinst )
      parameters:
        $moveinst, movement instruction;
          Compass direction (NSEW), In, Out, Home

      Moves camera according to the $movinst, for the approximateally the duration
      of the "delay" (whatever was set with setDelay, or default)
    
 
    moveDirectPT( $x, $y )
      parameters:
        $x, integer between 0 and 640
        $y, integer between 0 and 480

      Moves camera according to the xy point of $x and $y;
      accordingly to the current view of the camera.


    moveRelative( $moveDirection, $movePercentage )
      parameters:
        $moveDirection, compass direction.
        $movePercentage, 10,15,20,25,30,40,50,66.7,83.3, or 100.

      Moves camera accordingly to the $moveDirection by the
      percentage of the screen found in $movePercentage.


    moveToPreset( $preset )
      parameters:
        $preset, preset number.

      Moves camera to preset $preset.


    stop()

      Internal function.

      This will only need to be called if you wish to
      halt the camera's movement for some reason.


    rawVISCA( $visca )
      parameters:
        $visca, VISCA statement

      For use by people who know how to build a VISCA statement.


    captureToFile( $file )
      parameters:
        $file, filename to record current snapshot image to.

      Records current snapshot image (oneshotimage.jpg)


    setLogin( $username, $password )
      parameters:
        $username, camera username
        $password, camera password

      Sets the credentials for the camera.


    sendRequest( $type, $code )
      parameters:
        $type, 'visca', 'directpt', 'relative', or 'inquiry'
        $code, string to pass to camera

      Internal function.

      You will never need to call this.


    customDelay()
    
      Internal function.

      sleeps for the amount of milliseconds set in setDelay, or default.
    
=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make install

=head1 DEPENDENCIES

  HTTP::Request::Common
  LWP::UserAgent

=head1 BUGS

  Its beta with minimal functionality, here there be demons.

=head1 AUTHORS

Charles Morris <cmorris@cs.odu.edu>

special thanks to Ian Gullett <igullett@cs.odu.edu>,
for motivation to finish this,
and for certain insights into the `Abyss of Sony`.


