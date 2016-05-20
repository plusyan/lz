#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
say "This is test !!!";
__DATA__
rrdtool create sensor.rrd --step=1 --start= D3:movement:ABSOLUTE:60:0:1 RRA: