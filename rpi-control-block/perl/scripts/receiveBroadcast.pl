#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IO::Socket::Multicast;
use Data::Dumper;
my $data="";

my $s = IO::Socket::Multicast->new(LocalPort=>65432);
print Dumper \$s;

while (1){
	$s->mcast_add('225.0.1.1','wlp3s0');
	$s->recv($data,65432);
	$data=~s/[\n\r]//g;
	say $data;
}
