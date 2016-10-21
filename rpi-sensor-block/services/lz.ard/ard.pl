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
use Time::HiRes qw(usleep nanosleep);
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

$SIG{INT}=\&terminate;
$SIG{TERM}=\&terminate;

#
# TODO: Make sure that we empty the buffer of the /dev/ttyUSBX before we proceed. 
# I.e. check if we have multiple measurements in the buffer. If so, discard the data !
#

foreach my $ard (sort keys %cfg){
say "Before the fork ...";
    my $pid=fork();
    if ($pid == 0 ) {
        $|=1;
        say "Starting serial port reader for: $cfg{$ard}{port}";
        my $serial = Device::SerialPort->new($cfg{$ard}{port}, 0) || die "Can't open $cfg{$ard}{port}: $!\n";
        $serial->baudrate($cfg{$ard}{baudRate}) || die "Cannot set speed to $cfg{$ard}{baudRate} !";
        my $seq=0;
        
        my $serialConfigFile="$cfg{$ard}{pipeFile}" . "serial.config";
        if ( -f $serialConfigFile ){
            print  "Configuration file: $serialConfigFile exist. Deleting it ...";
            unless (unlink($serialConfigFile)){
                say "Failed: $!";
                
            }else{
                say "Done.";
            }
        }
        print "Saving configuration file: $serialConfigFile...";
        $serial->save($serialConfigFile) or
            die "Failed $!";
        say "Done";
            
        #
        # We only used the object $serial in order to create the configuration file.
        #
        
        $serial=undef;
        my $rw=IO::File->new();
        $rw->autoflush;
        $serial=tie (*$rw, 'Device::SerialPort', "$cfg{$ard}{port}");
        unless ($serial){
            #TODO: implement alert system to inform about the problem !!!
            die "Failed to open serial port:$cfg{$ard}{port} $!";
        }
        
        my $string="";
        my $pipe=IO::File->new();
        $pipe->autoflush;
        print  "Opening fifo: $cfg{$ard}{pipeFile} ...";
        unless (open ($pipe,">","$cfg{$ard}{pipeFile}")){
            say "Failed: $!";
            exit 1;
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
                    last if $char eq "\n";
                }
            }else{
                next;
            }
            
            unless ($string){
                #say "String is empty !!! Repeating !!!";
                next;
            }
            
            # Check if the string is completed by the EOL symbols, be it 0d, 0a, or both ! If so, send it via the pipe.
            if ($string=~m/[\n\r]/){
                $string=~s|[\n\r]{1,}||g;
                $seq++;
		#Create the header part !
                if ($string){
                    $string="v-f=0.1/id-s=$cfg{$ard}{id}/rndid-n=$randomID/seq-n=$seq/newseq-rxn=0|" . $string; # have the version predefined
                }else{
                    say "Empty string received from the sensor !";
                    $string="v-f=0.1/id-s=$cfg{$ard}{id}/rndid-n=$randomID/seq-n=$seq/newseq-rxn=0/err-text=noDataFromARDviaUSBport|";
                }
                $string="crc32-n=" . crc32($string)  ."/$string";
                print $pipe $string . "\n";
                $string="";
            }
        }
        
        
        
        #TODO: Try multiple times before give up !

        close ($pipe) or die "Cannot write to pipe. $!";
    }elsif ($pid > 0){
        push @pids,$pid;
    }else{
        say "Failed to fork child for port: $cfg{$ard}{port}\nReason:perl fork is not working !";
        exit 1;
    }

}
sleep 100 while 1;
