#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IPC::System::Simple 'systemx';
use Config::IniFiles;
use Data::Dumper;
use File::Basename;

my $gpioDaemon="/opt/lz/rpi-sensor-block/c/gpio/gpio";
my $configFile="../../config/sensor-gpio.conf";

say "lz gpio version 0.1 - parsing the config file: $configFile";

my @pids;
sub terminate {
    foreach (@pids){
        say "$$: Terminating process: $_";
        kill (15,$_);
    }
    say "$$: Exiting";
    exit 0;
}

my %processInfo=();
my %cfg;
my %duplicate; # Hash for check for duplicate fifos and id's ...
$configFile=dirname($0) .'/' . $configFile;

#TODO: Check for parsing errors !!!
tie %cfg, 'Config::IniFiles', ( -file => $configFile);

$|=1;
my @commands=();
foreach (sort keys (%cfg)){
    say "Checking section: [$_]";
    my @myKeys=qw (type id refreshTimeMs pipeFile dataType dataSpace comment);

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
            say "In config file: $configFile, section: $_:\n$configKey <===This key is unknown! It is either misspelled, or not supported !";
            exit 1;
        }
    }

    next unless (m/^\d{1,}$/);
    my @command=();
    push @command,$gpioDaemon;
    push @command,'-p';
    push @command,$_;

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

    print "Checking pin type ...";
    my $d=$cfg{$_}{type};
    if ($d=~m/^digital$/i) {
        print "digital";
        push @command,'-d';
    }elsif ($d=~m/^analog$/i){
        print "analog";
        push @command,'-a';
    }else{
        die "Fatal: Cannot determine pin type !!!";
    }
    say "...OK";
    
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
    
    push @command,'-f';
    push @command,$fifo;
    
    print "Checking refresh time ...";
    my $rt=$cfg{$_}{refreshTimeMs};
    unless ($rt=~m/^\d{3,8}$/){
        die "refreshTimeMs must be 3 to  8 digits number !";
    }

    say "$rt...OK";
    push @command,'-t';
    push @command,$rt;
    push @commands,\@command;
    
    my $dataType=$cfg{$_}{dataType};
    unless ($dataType eq 'NZ'){
        say "Currently only NZ format is supported for dataType !!!";
        exit 1;
    }
    
    my $dataSpace=$cfg{$_}{dataSpace};
    my ($begin,$end)=($1,$2) if ($dataSpace=~m/^(\d{1,})\;(\d{1,})$/);
    say "BEGIN: $begin, END: $end";
    unless (defined $begin && defined $end){
        say "Incorrect values for dataSpace";
        exit 1;
    }
    
    if ($begin > $end) {
        say "Begin variable for dataSpace cannot be smaller than end variable !!!";
        exit 1;
    }
    
    if ((length $cfg{$_}{comment }) > 100) {
        say "comment cannot exceed 100 characters !";
        exit 1;
    }
}

$SIG{INT}=\&terminate;
$SIG{TERM}=\&terminate;

foreach (@commands){
    my $pid = fork();
    die "Could not fork\n" if not defined $pid;
    
    if ($pid == 0){
        # The gpio.c is self preserving process. We do not need to restart or monitor it !
        say "$$: Executing: @$_ ";
        exec(@$_);
    }else{
        push @pids,$pid;
    }
}

sleep 100 while 1;

__END__

