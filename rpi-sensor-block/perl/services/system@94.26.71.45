#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

print  "Starting iptables firewall ... ";

my $f=`which iptables`;
die "No 'iptables' command found !" if ( $? != 0 );

chomp $f;
system ($f,'-F','-t','nat');
system($f,'-Z','-t','nat');

system($f,'-A', 'POSTROUTING', '-t', 'nat', '-s', '10.10.10.0/24', '-j', 'MASQUERADE');
die "Failed to initialize the firewall !!!" if ($? != 0 );

open (W,">/proc/sys/net/ipv4/ip_forward") or
    die "Failed to open file: /proc/sys/net/ipv4/ip_forward . The error was: $!";

print W '1';

close (W) or 
    die "Failed to write /proc/sys/net/ipv4/ip_forward . The error was: $!";

say "done";


__END__
