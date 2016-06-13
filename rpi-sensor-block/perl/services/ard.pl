#!/usr/bin/env perl

BEGIN {
    pop @INC;
    push @INC,"/opt/lz/modules";
}

use strict;
use warnings;
use feature 'say';
use Device::SerialPort qw( :PARAM :STAT 0.07 );
use Data::Dumper;
use Time::HiRes 'usleep';
use Config::IniFiles;
use File::Basename;
use Config::Ard;
use IO::File;


$|++;

my $configFile="../../config/sensor-ard.conf";

# Parse the config file here !!!
say "lz ardu version 0.1 - parsing the config file: $configFile";

my %cfg;
my @validConf=();
my %duplicate; # Hash for check for duplicate fifos and id's ...

$configFile=dirname($0) .'/' . $configFile;

my $c=Config::Ard->new($configFile);
$c or die "Failed to parse config file: $configFile. The error was:\n" . $c->getLastError;
my $cfg=$c->parse();
die $c->getLastError unless $cfg;

%cfg=%$cfg;
$c=undef;
$cfg=undef;

# TODO: Catch signals and terminate all forked processes !

say "Creating all FIFO files required:";

foreach (sort keys %cfg){
    my $fifo=$cfg{$_}{pipeFile};
    say "FIFO: $fifo";
    print "(re)creating: $fifo ...";
    if ( -e $fifo ) { 
        unlink ($fifo) or die "Cannot delete FIFO file: $fifo . The error was: $!";
    }
        
    system('mknod', $fifo, 'p') && die "can't mknod $fifo: $!";
    say "OK";    
}

my @pids=();
foreach my $ard (sort keys %cfg){
    
    my $pid=fork();
    if ($pid == 0 ) {
        $|=1;
        say "Starting serial port reader for: $cfg{$ard}{port}";
        my $serial = Device::SerialPort->new($cfg{$ard}{port}, 0) || die "Can't open $cfg{$ard}{port}: $!\n";
        $serial->baudrate($cfg{$ard}{baudRate}) || die "Cannot set speed to $cfg{$ard}{baudRate} !";
        my $seq=0;
        
        my $string=""; #; # get this from the config file !
        my $pipe=IO::File->new();
        $pipe->autoflush;
        unless (open ($pipe,">","$cfg{$ard}{pipeFile}")){
            say "Failed to open FIFO: $cfg{$ard}{pipeFile} $!";
            exit 1;
        }
        
        while (1){
            
            
            $|=1;
            # Create the header part
            my ($count,$buffer)=$serial->read($cfg{$ard}{buffer});
            $string .=$buffer;
            # Check if the string is completed by the EOL symbols, be it 0d, 0a, or both ! If so, send it via the pipe.
            
            if ($string=~m/[\n\r]/){
                $string=~s|[\n\r]{1,}||g;
                $seq++;
                $string="v-f:0.1 id-s:$cfg{$ard}{id} seq-n:$seq|" . $string; # have the version predefined
                say $pipe $string;
                $string="";
            }
            
            usleep 100; # get this from config file (maybe)
            
        }
        
        close ($pipe) or die "Cannot write to pipe. $!";
        
    }elsif ($pid > 0){
        push @pids,$pid;
    }else{
        say "Failed to fork child for port: $cfg{$ard}{port}\nReason:perl fork is not working !";
        exit 1;
    }
}
