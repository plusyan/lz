#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
say "This is test !!!";

package UDP::Transmit;

sub multicast {
    my %config=();
    my ($self,$message,$broadcastGroup,$broadcastPort,$localPort)=@_;
    unless ($message){
        
    }
}

1;