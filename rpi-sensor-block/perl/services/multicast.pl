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
        my $s=UDP::Multicast->new("wlan0","225.0.1.1","65432") or  # Where from to take this ???
            die "Failed to initiate: UDP::Multicast . The error was: " . UDP::Multicast->getLastError;
        while  ! (open(PIPE,"$fifo")){
            warn "Failed to open fife: $fifo ($!). Sleeping 5 minutes and repeating ...";
            sleep 300;
        }
        
        while (1) {
            my $message=<PIPE>;
            $s->send("$message") if ($message);
        }
            
        close (PIPE);    
    }elsif($pid > 0){
        next;
    }else{
        die "Cannot fork. Something with your system is broken !!! ($!)";
    }
}
close (FDIR);



# *. Get the addapter, multicast and port from somewhere.
# *. Shall we use only one multicast group ?
# *. Shall I have one more think ?
# *.


my $s=UDP::Multicast->new("wlan0","225.0.1.1","65432"); # Where from to take this ???
print Dumper \$s;
$s->send("HelloWorld");
