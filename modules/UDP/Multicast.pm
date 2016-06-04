#!/usr/bin/env perl

package UDP::Multicast;

#TODO: Eval arund each multicast call !
#TODO: Implement error reporting mechanism !!!

use strict;
use warnings;
use feature 'say';
use IO::Socket::Multicast;
use Data::Validate::IP 'is_multicast_ipv4';
sub new {
    my ($self,$nic,$mcastGroup,$port)=@_;
    my %config=();
    
    unless ($nic){
        say "UDP::Multicast No NIC supplied !";
        return undef;
    }
    
    unless ($port=~m/^\d{1,5}/){
        say "UDP::Multicast No port specified !";
        return undef;
    }
    
    if ($port <1 || $port > 65536) {
        say "UDP::Multicast port must be [1-65535]";
        return undef;
    }
    
    # Check if the multicast group is correctly choosen ...
    unless (is_multicast_ipv4($mcastGroup)){
        say "$mcastGroup is not IPv4 mulsticast group !!!";
        return undef;
    }
    
    my $s=IO::Socket::Multicast->new( ReuseAddr=>1);
    unless ($s){
        say "Failed to initialize IO::Socket::Multicast !";
        return undef;
    }
    
    $config{nic}=$nic;
    $config{mcastGroup}=$mcastGroup;
    $config{port}=$port;
    $config{s}=$s;
    
    return bless \%config;
}

sub send{
    my ($self,$message)=@_;
    unless ($message){
        say "UDP::Multicast No message ! Nothing to send !";
        return undef;
    }
        
    unless (defined $$self{s}){
        say "UDP::Multicast is not initialized! Please use 'new' method to do so !";
        return undef;
    }
    
    my $s = $$self{s};
    $s->mcast_if($$self{nic});
    $s->mcast_ttl(10);
    $s->mcast_send($message,"$$self{mcastGroup}:$$self{port}");
}

receive{
    say "UNDER CONSTRUCTION ...";
    return undef;
}

1;

__END__
