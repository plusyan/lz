#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';


#### Use file slurp in ram disk to preserve the card !!!

my $template="%model%|%type%|%analogue%|N|0-255|115|light sensor to detect movement via IR light mounted on the roof top.";
my $message="ir|S|A|N|0-255|115|light sensor to detect movement via IR light mounted on the roof top.";
my $file="/data/tmp/mmap";

use File::Map 'map_file';
map_file my $map, $file, '+<';
$map=$message;
say $map;



 