
#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

my $rPi="192.168.1.10";

say "Connecting to your raspberry pi ($rPi)";

system("sshfs pi\@$rPi:/ /data/mount/rpi");



__END__
