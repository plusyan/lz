package Sensor::Signal;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use String::CRC32;
require "/opt/lz/modules/errorHandler.pl";

sub new {
    my %config=();
    return bless \%config;
}

sub validateCRC32 {
    my ($self,$string)=@_;
    my $crc32=$1 if ($string=~m/crc32-n=(\d*) /);
    unless ($crc32){
        $self->setLastError("Cannot find crc32-n= in $string !");
        return undef;
    }
    $string=~s/crc32-n=$crc32 //;
    my $newcrc32=crc32($string);
    return 'validated' if ( $newcrc32 ==  $crc32);
    $self->setLastError("String: [$string] contains invalid CRC32!  Have:$crc32,must be:$newcrc32");
    return undef;
}

sub decode{
    my ($self,$string)=@_;
    my %result=();
    if ($string eq ''){
        $self->setLastError("Empty string sent ! Need decrypted string sent by the sensor !");
        return undef;
    }
    
    return undef unless $self->validateCRC32($string);
    
    my @parts=split('\|',$string);
    if ($#parts !=  1){
        $self->setLastError("String: [$string] contains more then one '|' character. Cannot separate header from data !");
        return undef;
    }
    my $rawData=pop @parts;
    my $header=pop @parts;
    
    # Check if there is sensor failure first !
    if ($header=~m/err-text=(.*) {0,}/){
        $self->setLastError("sensorError=$1");
        return undef;
    }

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
            $self->setLastError("Data contains too many '=' signs ($#varVal) in string:" . join('=',@varVal));
            return undef;
        }
        
        $result{data}{$varVal[0]}=$varVal[1];
    }
    
    return \%result;
}

1;