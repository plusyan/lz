#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

my $rPi="10.10.10.1";

say "Connecting to your raspberry pi ($rPi)";

system("sshfs pi\@10.10.10.1:/ /data/mount/rpi");



__END__
