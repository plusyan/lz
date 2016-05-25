#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IO::Socket::Multicast;
my $data="";

my $s = IO::Socket::Multicast->new(LocalPort=>65432);
while (1){
	$s->mcast_add('225.0.1.1','wlan0');
	$s->recv($data,65432);
	say $data;
}
