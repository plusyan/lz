#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

print  "Starting iptables firewall ... ";

my $f=`which iptables`;
chomp $f;
exit 1 if ( $? != 0 );


system ($f,'-F','-t','nat');
system($f,'-Z','-t','nat');

system($f,'-A', 'POSTROUTING', '-t', 'nat', '-s', '10.10.10.0/24', '-j', 'MASQUERADE');


open (W,">/proc/sys/net/ipv4/ip_forward") or 
    die "Failed to open file: /proc/sys/net/ipv4/ip_forward . The error was: $!";

print W '1';

close (W) or 
    die "Failed to write /proc/sys/net/ipv4/ip_forward . The error was: $!";




exit 1 if ($? != 0 );

say "done";
__DATA__

sysctl 
