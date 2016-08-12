package Sensor::Signal;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
require "/opt/lz/modules/errorHandler.pl";

sub new {
    my %config=();
    return bless \%config;

}

sub decode{
    my ($self,$string)=@_;
    if ($string eq ''){
        $self->setLastError("Empty string sent ! Need decrypted string sent by the sensor !");
    }
}

1;