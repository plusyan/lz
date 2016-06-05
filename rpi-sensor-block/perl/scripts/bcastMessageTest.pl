#!/usr/bin/env perl 

BEGIN {
    pop @INC;
    push @INC,"/opt/lz/modules";
}


use strict;
use warnings;
use feature 'say';
use UDP::Multicast;
use Data::Dumper;

my $s=UDP::Multicast->new("wlan0","225.0.1.1","65432");
print Dumper \$s;
$s->send("HelloWorld");

__DATA__


