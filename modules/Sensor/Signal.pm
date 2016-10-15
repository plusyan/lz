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
    my $crc32=$1 if ($string=~m/crc32-n=(\d*)\//);
    unless ($crc32){
        $self->setLastError("Cannot find crc32-n= in $string !");
        return undef;
    }
    $string=~s/crc32-n=$crc32\///;
    my $newcrc32=crc32($string);
    return 'validated' if ( $newcrc32 ==  $crc32);
    $self->setLastError("WARNING: The sensor data was tampered with durring the transmission!!!\nString: [$string] contains invalid CRC32!  Have:$crc32,must be:$newcrc32.");
    return undef;
}

sub parseVarVal{ 
    my ($self,$string)=@_;
    my %result=();
    my @rawData=split('/',$string);
    #
    # Split var1=val1/var2=var2 sequence into array.
    #
    if ($#rawData == -1){
        $self->setLastError("String: $string does not contain valid data separated by '/' !");
        return undef;
    }
    foreach (@rawData){
        my @varVal=split('=',$_);
        if ($#varVal == -1){
            $self->setLastError("Empty variable=value combination detected !");
            return undef;
        }
        if ($#varVal != 1){
            $self->setLastError("Too many '=' signs ($#varVal) in string: @varVal");
            return undef;
        }
        
        if (defined $result{$varVal[0]}){
            $self->setLastError("Variable $varVal[0] allready exists and have value:[$result{envelop}{$varVal[0]}]");
            return undef;
        }
        
        $result{$varVal[0]}=$varVal[1]; # Empty value is fine.
    }
    return \%result
    
    
}

sub decode{
    my ($self,$string)=@_;
    my %result=();
    if ($string eq ''){
        $self->setLastError("Empty string sent ! Need decrypted string sent by the sensor block!");
        return undef;
    }
    
    return undef unless $self->validateCRC32($string);
    
    my @parts=split('\|',$string);
    #
    # We need 3 parts: the sender envelop, the device description and the actual device data.
    #
    
    my $data=pop @parts;
    my $deviceDesc=pop @parts;
    my $envelop=pop @parts;
    my $r=undef;
    
    #
    # Parse the envelop
    #
    
    unless ($r=$self->parseVarVal($envelop)){
        $self->setLastError("Failed to parse envelop. The error was: " . $self->getLastError);
        return undef;
    }
    
    $result{envelop}=$r;
    if ($result{envelop}{'err-text'}){
        $self->setLastError("sensorEnvelopError=$result{envelop}{'err-text'}");
        return undef;
    }
    
    #
    # Parse the device description
    #

    unless ($r=$self->parseVarVal($deviceDesc)){
        $self->setLastError("Failed to parse deviceDesc. The error was: " . $self->getLastError);
        return undef;
    }
    $result{deviceDesc}=$r;
    if ($result{deviceDesc}{'err-text'}){
        $self->setLastError("sensorDeviceDesc=$result{deviceDesc}{'err-text'}");
        return undef;
    }
    
    #
    # Parse the sensor data
    #
    
    
    unless ($r=$self->parseVarVal($data)){
        $self->setLastError("Failed to parse sensor data. The error was: " . $self->getLastError);
        return undef;
    }
    $result{data}=$r;
    if ($result{data}{'err-text'}){
        $self->setLastError("sensorData=$result{data}{'err-text'}");
        return undef;
    }

    return \%result;

}

1;