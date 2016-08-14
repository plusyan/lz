#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use IO::Socket::Multicast;
use Data::Dumper;

###################################################################################
#
# 225.0.1.1   used for basic sensor transmission
# 225.0.1.100 used by the actuators.
#
###################################################################################
##
##
## broadcastMessage -f pipe -m message template
##
##
my $sleepTime=500; # In  miliseconds
$|++;
my $pipe="/data/tmp/sensor_ir";
(-p $pipe) or die "No pipe file: $pipe";
my $counter=0;

while (1) {
    $counter++;

#     print "Waiting for message on pipe: $pipe.";
    open(PIPE,"$pipe") or die "Failed to open pipe: $pipe . The error was: $!";
    my $sensorData=<PIPE>;
    close (PIPE);
    $sensorData or next;

    chomp $sensorData;
  #  say $sensorData;

    # Replace this with template !!!
    my $message="ir_sensor_model|$sensorData|$counter|$sleepTime|D|NZ|0-1|light sensor";
    my %conf=(
        multicastGroup => "225.0.1.1",
        multicastPort => "65432",
        localPort => "65431",
        nic => "wlan0",
        ttl => 10
    );

#     say "Transmitting your sensor message to multicastGroup: $conf{multicastGroup}, port: $conf{multicastPort}, using local port: $conf{localPort}";

    my $s = IO::Socket::Multicast->new(LocalPort=>$conf{localPort});
    $s->mcast_if($conf{nic});
    $s->mcast_ttl($conf{ttl});
    $s->mcast_loopback(0);
    my $result=$s->mcast_send($message,"$conf{multicastGroup}:$conf{multicastPort}");

}

__DATA__
# Message example:
