package Config::Ard;

use strict;
use warnings;
use feature 'say';
use Config::IniFiles;
use Data::Dumper;
require "/opt/lz/modules/errorHandler.pl";

sub new{
    my %config=();
    my ($self,$configFile)=@_;
    unless (defined $configFile){
        $self->setLastError("Need configuration file to proceed !");
        return undef;
    }
    $config{init}=1; # Marking this module as initialized !
    $config{file}=$configFile;
    return bless \%config;
}

sub parse{
    my $self=shift;
    
    # We only use the follwoing sections !
    my @mySections=qw (id port pipeFile refreshTimeMicroS buffer comment baudRate);
    my %duplicate=();
    my $configFile=$self->getConfigValue('file');
    unless (defined $configFile){
        $self->getLastError("No configuration file defined. Is this module initialized via new method ?");
        return undef;
    }
    
    my %cfg=();
    tie %cfg, 'Config::IniFiles', (-file => $configFile);
    if (@Config::IniFiles::errors) {
        $self->setLastError("Failed to parse config file: $configFile. The error was:\n@Config::IniFiles::errors");
        return undef;
    }

    foreach (sort keys (%cfg)){
        unless (m/^ard-\d{1,}$/i){
            $self->setLastError("In config file: $configFile, section: $_: unknown section: $_");
            return undef;
        }
        
        say "Checking section: [$_]";
        foreach my $configKey (keys $cfg{$_}){
            my $found=0;
            foreach (@mySections){
                if ($configKey eq $_) {
                    say "$configKey was found !!!";
                    $found++;
                    next;
                }
            }
            
            if ($found == 0){
                $self->setLastError("$configKey <===This key is unknown ! It is either misspelled, or not supported !");
                return undef;
            }
            
        }
        
        print  "Checking id:$cfg{$_}{id} ...";
        my $id=$cfg{$_}{id};
        unless ($id=~m/^[a-zA-Z0-9]{10}$/) {
            $self->setLastError("Incorrect ID ! Must be 10 characters long and may include one or more of the following: a-zA-Z0-9");
            return undef;
        }    
                
        if (exists $duplicate{$id}){
            $self->setLastError("In config file: $configFile, section: $_: Duplicate ID detected. The same ID was located in section: $duplicate{$id}{section}.");
            return undef;
        }
    
        $duplicate{$id}{section}=$_;
        say "OK !";
    
        print "Checking the buffer...";
        my $buffer=$cfg{$_}{buffer};
        unless ($buffer=~m/^\d{1,}$/){
            $self->setLastError("In config file: $configFile, section: $_: Buffer must be number > 1 and < 10000");
            return undef;
        }
        if ($buffer < 1 || $buffer > 10000) {
            $self->setLastError("In config file: $configFile, section: $_: Buffer must be [1;10000]");
            return undef;
        }
        
        
        print "Checking baud rate ...";
        my $br=$cfg{$_}{baudRate};
        my @baudRates=(300,600,1200,1600,2400,4800,9600);
        my $found=0;
        foreach my $baudRate (@baudRates){
            $found=1 if ($baudRate == $br);
        }
        unless ($found){
            $self->setLastError("In config file: $configFile, section: $_: Invalid baud rate: $br. Must be one of: @baudRates");
            return undef;
        }
        say "OK";
        
        my $fifo=$cfg{$_}{pipeFile};
        
        if (exists $duplicate{$fifo}){
            $self->setLastError("In config file: $configFile, section: $_: Duplicate FIFO detected. The same FIFO was located in section: $duplicate{$fifo}{section}");
            return undef;
        }
        
        $duplicate{$fifo}{section}=$_;
        
        print "Checking FIFO file: $cfg{$_}{pipeFile} ... ";
        
        if ($fifo=~m/[%:\$\n\t`\\]/g){
            $self->setLastError("In config file: $configFile, section: $_: File name contains invalid character !");
            return undef;
        }
        
        print "Checking refresh time ...";
        my $rt=$cfg{$_}{refreshTimeMicroS};
        unless ($rt=~m/^\d{3,8}$/){
            $self->setLastError("In config file: $configFile, section: $_: refreshTimeMs must be 3 to  8 digits number !");
            return undef;
        }
        say "$rt...OK";        
    }    
    return \%cfg;
        
}

1;

__DATA__
