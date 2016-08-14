#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Cwd;

my $workDir="/opt/lz/rpi-sensor-block/c/gpio";

chdir  $workDir or die "Failed to change directory to: $workDir . The error was: $!";

while(1){
    system("make clean");
    system("make");
    system("/opt/lz/rpi-sensor-block/c/gpio/gpio");
    $workDir=<>;
    if ($workDir=~m/^q|quit|exit$/i){
        say "Bye.";
        exit 1;
    }
}
