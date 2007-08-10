#!perl

use warnings;
use strict;

use Test::More tests => 5;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

NO_METACHARCTERS: {
    my @expected = qw(
        t/swamp/Makefile
        t/swamp/Makefile.PL
    );
    my $regex = 'Makefile';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $regex" );
}


METACHARACTERS: {
    my @expected = qw(
        t/swamp/html.htm
        t/swamp/html.html
    );
    my $regex = 'swam.......htm';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $regex" );
}


FRONT_ANCHOR: {
    my @expected = qw(
        squash
    );
    my $regex = '^s';

    my @files = qw( . );
    my @args = ( '-g', $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $regex" );
}


BACK_ANCHOR: {
    my @expected = qw(
        t/swamp/moose-andy.jpg
    );
    my $regex = 'g$';

    my @files = qw( . );
    my @args = ( '-a', '-g', $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $regex" );
}


CASE_INSENSITIVE: {
    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = 'PIPE';

    my @files = qw( . );
    my @args = ( '-i', '-g', $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $regex, case-insensitive" );
}
