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
use Config::IniFiles;
use File::Basename;
use Config::Ard;
use IO::File;
use IO::Select;
use String::CRC32;
$|=1;
my @pids=();

sub terminate {
    say "$$: Received signal: " . shift;
    if ($#pids == -1){ 
        say "$$: Exiting.";
        exit 0; 
    };
    foreach (@pids){
        say "Killing child process: $_ ...";
        kill (15,$_) or warn "Failed to kill process: $_. The error was: $!";
    }
    exit 0;
}

$|++;

my $configFile="../../config/sensor-ard.conf";

# Parse the config file here !!!
say "lz ard version 0.1 - parsing the config file: $configFile";

my %cfg;
my @validConf=();
my %duplicate; # Hash for check for duplicate config values.


#
# Parse the configuration file.
#

$configFile=dirname($0) .'/' . $configFile;
my ($c,$cfg)=undef;
while (1){
    $c=Config::Ard->new($configFile);
    unless ($c){
        say "Failed to parse config file: $configFile. The error was:\n" . $c->getLastError;
        say "Sleeping one 10 secondes and repeating ...";
        sleep 10; next;
    }
    $cfg=$c->parse();
    unless ($cfg){
        say $c->getLastError;
        say "Sleeping 10 secondes and repeating";
        sleep 10; next;
    }
    last;
}

%cfg=%$cfg;
$c=undef;
$cfg=undef;

say "Creating all FIFO files required:";

foreach (sort keys %cfg){
    my $fifo=$cfg{$_}{pipeFile};
    print "(re)creating: $fifo ...";
    if ( -e $fifo ) { 
        unless (unlink ($fifo)){
            say "Cannot delete FIFO file: $fifo . The error was: $!";
            say "Sleeping 10 seconds and repeating";
            sleep 10; redo;
        }
    }
    system('mknod', $fifo, 'p');
    if ($? != 0 ){
        say "can't mknod $fifo: $!";
        say "Sleeping 10 seconds and repeating.";
        sleep 10; redo;
    }
    say "OK";
}

$SIG{INT}=\&terminate;
$SIG{TERM}=\&terminate;

foreach my $ard (sort keys %cfg){
    my $pid=fork();
    if ($pid == 0 ) {
        $|=1;
        say "Starting serial port reader for: $cfg{$ard}{port}";
        my $serial=undef;
        
        my $seq=0;
        
        my $rw=IO::File->new();
        $rw->autoflush;
        print "Using 'tie' to associate  $cfg{$ard}{port} with file handler ...";
        while (1){
            $serial=tie (*$rw, 'Device::SerialPort', "$cfg{$ard}{port}");
            unless ($serial){
                #TODO: implement alert system to inform about the problem !!!
                say "Failed to open serial port:$cfg{$ard}{port} $!";
                say "Sleeping 10 seconds and repeating ...";
                sleep 10;
                next;
            }
            last;
        }
        say "Done.";
        $serial->purge_all;
        
        my $string="";
        my $pipe=IO::File->new();
        $pipe->autoflush;
        
        print  "Opening fifo: $cfg{$ard}{pipeFile} ...";
        
        while (1){
            unless (open ($pipe,">","$cfg{$ard}{pipeFile}")){
                say "Failed: $!";
                say "Sleeping 10 seconds and repeating ...";
                sleep 10;
                next;
            }
            last;
        }
        say "Done";
        my $randomID=int(rand(10000)) . int(rand(10000)) . int(rand(10000));   
        my $s=IO::Select->new();
        $s->add($rw);
        while (1){
            $string=undef;
            if ($s->can_read()){
                my $char=undef;
                while (1){
                    if (read($rw,$char,1)){
                        $string .=$char;    
                    }
                    last if ($char eq "\n");
                }
            }else{
                next;
            }
            unless ($string){
                #say "String is empty !!! Repeating !!!";
                next;
            }
            
            #
            # Sometimes it is possible to receive empty string. If so, ignore it and move on.
            #TODO: Count the number of empty strings. If they reach certain ammount, ring the bell ...
            #
                            
            $string=~s|[\n\r]{1,}||g;                
            if ($string){
                $seq++;
                $string="v-f=0.1/id-s=$cfg{$ard}{id}/rndid-n=$randomID/seq-n=$seq/newseq-rxn=0|" . $string; # have the version predefined
                $string="crc32-n=" . crc32($string)  ."/$string";
                print $pipe $string . "\n";
                $string="";
            }
            
        }
        close ($pipe) or warn "WARNING: Cannot write to pipe: $!\nPossible data loss !";
    }elsif ($pid > 0){
        push @pids,$pid;
    }else{
        say "Failed to fork child for port: $cfg{$ard}{port}\nReason:perl fork is not working !";
        say "Sleeping 2 seconds and repeating ...";
        sleep 2;
        redo;
    }
}
sleep 100 while 1;
