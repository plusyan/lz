#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IPC::System::Simple 'systemx';
use Config::IniFiles;
use Data::Dumper;

my $gpioDaemon="/data/c/gpio/gpio";
my $configFile="/home/iliyan/Desktop/site/iot/raspberryPi/lz/scripts/services/lz-gpio.conf";

say "lz gpio version 0.1 - parsing the config file: $configFile";

my %processInfo=();
my %cfg;
my %duplicate; # Hash for check for duplicate fifos and id's ...

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
            say "$configKey <===This key was not defined in our module ! It is either misspelled, or not supported !";
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

# Capture all signals here and terminate all processes before exit !


my %procTable=();
foreach (@commands){
    say "@$_";
    my $pid = fork();
    die "Could not fork\n" if not defined $pid;
    
    if ($pid == 0){
        eval {systemx(@$_);};
        if ($@){
            say "Fatal error occured while executing the following command: @$_ : \n $@";
            return;
        }
    }else{
        $procTable{$pid}=$_;
    }
}

__DATA__

say "Exec: $gpioDaemon -d -f /data/tmp/sensor_ir -p 0 -t 500";
exec ("$gpioDaemon -d -f /data/tmp/sensor_ir -p  0 -t 500 &");

