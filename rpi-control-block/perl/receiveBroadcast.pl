#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IO::Socket::Multicast;
use Data::Dumper;
use Sensor::Signal;
$|=1;

my $data="";
#TODO: Check if we are allready running !
my $s = IO::Socket::Multicast->new(LocalPort=>65432);

my $sensor=Sensor::Signal->new;

while (1){
	$s->mcast_add('225.0.1.1','wlp3s0');
	$s->recv($data,65432);
	$data=~s/[\n\r]//g;
	say $data;
	# Decode the data here !
	my $sensorData=$sensor->decode($data);
	$sensorData or say $sensor->getLastError();	
}
