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
$|++;
my $pipe="/data/tmp/sensor_ir";
(-p $pipe) or die "No pipe file: $pipe";

# Open the pipe in blocking mode !!!
print "Waiting for message on pipe: $pipe.";
open(PIPE,"$pipe") or die "Failed to open pipe: $pipe . The error was: $!";
my $message=<PIPE>;
close (PIPE);

chomp $message;
say $message;

# Message here is moked up. To be used from some different place !!!
# my $message="ir_sensor_model|A|N|0-255|115|light sensor to detect sun light mounted on the roof top.";

my %conf=(
    multicastGroup => "225.0.1.1",
    multicastPort => "65432",
    localPort => "65431",
    nic => "wlan0",
    ttl => 10
);

say "Transmitting your sensor message to multicastGroup: $conf{multicastGroup}, port: $conf{multicastPort}, using local port: $conf{localPort}";

my $s = IO::Socket::Multicast->new(LocalPort=>$conf{localPort});
$s->mcast_if($conf{nic});
$s->mcast_ttl($conf{ttl});
$s->mcast_loopback(0);

my $result=$s->mcast_send($message,"$conf{multicastGroup}:$conf{multicastPort}");

if ($result == 0) {
    say "Failed to send the message - $result !";
    exit 1;
}

say "Message:\n[$message]\nsuccessfully transmitted !";
