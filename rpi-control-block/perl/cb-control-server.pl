#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use UDS::Server::Dispatch;
use Data::Dumper;

my $socketFile="/data/tmp/serverSocket";
my $s=UDS::Server::Dispatch->new();
unless ($s){
    die "Failed to initialize the server. The error was: " . UDS::Server::Dispatch->getLastError();
}


sub server {
    say "This is the server !!!";

    my ($message)=@_;
    say "Got message: '$message' on socket !";
    $s->send("HEllo, client !");
    say "Sent the message, now we need to register the client ...";
}

if (-e $socketFile){
    system("rm -f $socketFile");
}

unless ($s->server($socketFile,\&server)){
    say "Failed to activate the server !!!";
    say "The error was: " . $s->getLastError;

}

sleep 10 while 1;
