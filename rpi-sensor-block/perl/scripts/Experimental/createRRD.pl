#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
say "This is test !!!";
my $t=time;
say $t

__DATA__
rrdtool create sensor.rrd --step=1 --start=1463769466 DS:movement:ABSOLUTE:60:0:1 RRA:AVERAGE:0.1:1:1500000
rrdtool update sensor.rrd 1463769467:1
rrdtool fetch sensor.rrd  -s 1463769466 -e 1463769472 AVERAGE
rrdtool graph semsor.rrd DEF:var=rrd:DS:AVARAGE LINE:var#hex-rgb-color:Comment
