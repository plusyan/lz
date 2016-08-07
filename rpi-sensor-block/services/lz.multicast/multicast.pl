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
use IO::File;
use Crypt::Cipher::AES;

say "Sleeping 60 seconds to allow all drivers to start ...";
sleep 60;

my $fifoPath="/data/tmp"; # Take this from somewhere ...

opendir(FDIR,$fifoPath) or
    die "Failed to open directory: $fifoPath. The error was: $!";

foreach (readdir(FDIR)){
    next if (m/^\.{1,2}$/);
    my $fifo="$fifoPath/$_";
    next unless (-p $fifo);
    say $fifo;
    my $pid=fork();
    if ($pid == 0){    
        say "Forked to transmit the contents of $fifo ...";
        my $s=UDP::Multicast->new("wlan0","225.0.1.1","65432") or ###### Where from to take this ???
            die "Failed to initiate: UDP::Multicast . The error was: " . UDP::Multicast->getLastError;
        my $fh=IO::File->new();
        while ( ! (open($fh,"$fifo"))){
            warn "Failed to open fife: $fifo ($!). Sleeping 5 minutes and repeating ...";
            sleep 300;
        }
        while (<$fh>){
           s/[\n\r]//g;
           $s->send("$_") if ($_);
        }
        say "Fatal: Failed to read from pipe: $fifo ! Unknown error !";
        exit 1;
    }elsif($pid > 0){
        next;
    }else{
        die "Cannot fork. Something with your system is broken !!! ($!)";
    }
}
close (FDIR);
