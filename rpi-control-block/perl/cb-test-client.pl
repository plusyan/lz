#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use IO::Socket::UNIX qw( SOCK_STREAM );

my $socket_path = '/data/tmp/serverSocket';
say "Openning commection to the server ...";
my $socket = IO::Socket::UNIX->new(
   Type => SOCK_STREAM,
   Peer => $socket_path,
)   or die("Can't connect to server: $!\n");
say "Done ...";
say "Sending command: 'register'";

say $socket "register";
say "Waiting for response ...";
while (1){
    chomp( my $line = <$socket> );
    if ($line){
        say "Got response: ";
        say "$line";
    }
    #my $string=<>;
    #print $socket $string;
}

__DATA__

/data/tmp/sensors/add_header
/data/tmp/sensor/encrypt_data
/data/tmp/sensor/multicast_data
