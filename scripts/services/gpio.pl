#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IPC::System::Simple 'systemx';
use Config::IniFiles;
use Data::Dumper;

my $gpioDaemon="/data/c/gpio/gpio";
my $configFile="/data/config/lz-gpio.conf";
say "lz gpio version 0.1 - parsing the config file: $configFile";

my %processInfo=();
my %cfg;

#TODO: Check for errors !!!
tie %cfg, 'Config::IniFiles', ( -file => $configFile);

$|=1;
my @commands=();
foreach (sort keys (%cfg)){
    next unless (m/^\d{1,}$/);
    my @command=();
    push @command,$gpioDaemon;
    push @command,'-p';
    push @command,$_;
    
    print  "Checking id:$cfg{$_}{id} ...";
    unless ($cfg{$_}{id}=~m/^[a-zA-Z0-9]{10}$/) {
        say "Incorrect ID ! Must be 10 characters long and may include one or more of the following: a-zA-Z0-9";
        exit 1;
    }
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
    # TODO: Check the other parameters here too !!!
    say "$rt...OK";
    push @command,'-t';
    push @command,$rt;
    push @commands,\@command;
}

# TODO: Check if we have duplicate FIFO or ID;s !



# Capture all signals here and terminate all processes before exit !

# Loop this untill we start all processes.
my %procTable=();
foreach (@commands){
    say "@$_";
    my $pid = fork();
    die "Could not fork\n" if not defined $pid;
    
    if ($pid == 0){
        systemx(@$_);
    }else{
        $procTable{$pid}=$_;
    }
}

__DATA__

say "Exec: $gpioDaemon -d -f /data/tmp/sensor_ir -p 0 -t 500";
exec ("$gpioDaemon -d -f /data/tmp/sensor_ir -p  0 -t 500 &");

