package Config::Ard;

use strict;
use warnings;
use feature 'say';
use Config::IniFiles;
require "/opt/lz/modules/errorHandler.pl";

sub new{
    my %config=();
    my ($self,$configFile)=@_;
    unless (defined $configFile){
        $self->setLastError("Need configuration file to proceed !");
        return undef;
    }
    $config{file}=$configFile;
    return bless \%config;
}

sub parse{
    my $self=shift;
    my $configFile=$self->getValue('file');
    unless (defined $configFile){
        $self->getLastError("No configuration file defined. Is this module initialized via new method ?");
        return undef;
    }
    $self->setLastError("Under Construction.");
    return undef;
    
}




1;


__DATA__
#TODO: Check for parsing errors !!!
tie %cfg, 'Config::IniFiles', ( -file => $configFile);

my %ard=();

foreach (sort keys (%cfg)){
    say "Checking section: [$_]";
    my @myKeys=qw (id port pipeFile refreshTimeMicroS buffer comment baudRate);

    foreach my $configKey (keys $cfg{$_}){
        my $found=0;
        foreach (@myKeys){
            if ($configKey eq $_) {
                say "$configKey was found !!!";
                $found++;
                next;
            }
        }
        if ($found == 0){
            say "$configKey <===This key is unknown ! It is either misspelled, or not supported !";
            exit 1;
        }
    }

    next unless (m/^ard-\d{1,}$/i);

    print  "Checking id:$cfg{$_}{id} ...";
    my $id=$cfg{$_}{id};
    unless ($id=~m/^[a-zA-Z0-9]{10}$/) {
        say "Incorrect ID ! Must be 10 characters long and may include one or more of the following: a-zA-Z0-9";
        exit 1;
    }

    if (exists $duplicate{$id}){
        say "Duplicate ID detected. The same ID was located in section: $duplicate{$id}{section}";
        exit 1;
    }

    $duplicate{$id}{section}=$_;
    say "OK !";

    print "Checking the buffer...";
    my $buffer=$cfg{$_}{buffer};
    unless ($buffer=~m/^\d{1,}$/){
        say "Buffer must be number > 1 and < 10000";
        exit 1;
    }
    if ($buffer < 1 || $buffer > 10000) {
        say "Buffer must be [1;10000]";
        exit 1;
    }
    
    
    print "Checking baud rate ...";
    my $br=$cfg{$_}{baudRate};
    my @baudRates=(300,600,1200,1600,2400,4800,9600);
    my $found=0;
    foreach my $baudRate (@baudRates){
        $found=1 if ($baudRate == $br);
    }
    unless ($found){
        say "Invalid baud rate: $br. Must be one of: @baudRates";
        exit 1;
    }
    say "OK";
    
    my $fifo=$cfg{$_}{pipeFile};
    
    if (exists $duplicate{$fifo}){
        say "Duplicate FIFO detected. The same FIFO was located in section: $duplicate{$fifo}{section}";
        exit 1;
    }
    $duplicate{$fifo}{section}=$_;
    
    print "Checking FIFO file: $cfg{$_}{pipeFile} ... ";
    if ( -e $fifo ) { 
        unlink ($fifo) or die "Cannot delete FIFO file: $fifo . The error was: $!";
    }
    
    if ($fifo=~m/[\$\n\t`\\]/g){
        die "File name contains incorrect character !";
    }
    
    system('mknod', $fifo, 'p') && die "can't mknod $fifo: $!";
    say "OK";
    
    
    print "Checking refresh time ...";
    my $rt=$cfg{$_}{refreshTimeMicroS};
    unless ($rt=~m/^\d{3,8}$/){
        die "refreshTimeMs must be 3 to  8 digits number !";
    }
    say "$rt...OK";
    
    say "Saving the config ...";
    
    push @validConf,$_;
    
}



