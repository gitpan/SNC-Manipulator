#!/usr/local/bin/perl
use warnings;
use SNC::Manipulator;

$cam = new SNC::Manipulator( '10.10.10.1', '8080' );

$cam->setLogin( 'admin', 'pass' );

%info = $cam->inquiry('sysinfo');
print "Camera: " . $info{'TitleBar'} . "\n";

$cam->setDelay(1000);

$cam->move("left");
$cam->move("right");
$cam->move("right");
$cam->move("left");

$cam->moveToPreset(0);

