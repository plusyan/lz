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
    my %result=();
    if ($string eq ''){
        $self->setLastError("Empty string sent ! Need decrypted string sent by the sensor !");
        return undef;
    }
    
    #TODO:  Validate the CRC first !!!
    my ($header,$rawData)=split('\|',$string);
    
    # Check if there is sensor failure first !
    if ($header=~m/err-text=(.*) {0,}/){
        $self->setLastError("sensorError=$1");
        return undef;
    }
    
    say "h=>$header";
    say "r=>$rawData";
    
    #############################################
    #                                           #
    # Check if we have more then one '|' sign ! #
    #                                           #
    #############################################
    
    # Parse the header here !
    my @header=split(' ',$header);
    if ($#header == -1){
        $self->setLastError("String: $string does not contain valid header part ! Header and data are separeted by single '|' sign !");
        return undef;
    }
    $result{header}={};
    
    my @data=split(' ',$rawData);
    if ($#data == -1){
        $self->setLastError("String: $string does not contain valid data part !  Header and data are separeted by single '|' sign !");
        return undef;
    }
    $result{data}={};
    
    
    foreach (@header){
        # Ignore the CRC32 because we allready checked it, and will remove it form our working solution.
        next if m/crc\d{2}-n=/;
        my @varVal=split('=',$_);
        if ($#varVal == -1){
            $self->setLastError("Empty variable=value combination detected !");
            return undef;
        }
        if ($#varVal != 1){
            $self->setLastError("Too many '=' signs ($#varVal) in string: @varVal");
            return undef;
        }
        
        $result{header}{$varVal[0]}=$varVal[1];
    }
    
    foreach (@data){
        # Ignore the CRC32 because we allready checked it, and will remove it form our working solution.
        next if m/crc\d{2}-n=/;
        my @varVal=split('=',$_);
        if ($#varVal == -1){
            $self->setLastError("Empty variable=value combination detected in data part!");
            return undef;
        }
        if ($#varVal != 1){
            $self->setLastError("Data contains too many '=' signs ($#varVal) in string: @varVal");
            return undef;
        }
        
        $result{data}{$varVal[0]}=$varVal[1];
    }
    
    say "Parsed header !!!";
    print Dumper \%result;
    return \%result;
}

1;