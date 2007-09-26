#!perl

use warnings;
use strict;

use Test::More tests => 6;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

SINGLE_TEXT_MATCH: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -1 -h --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first instance of Sue!' );
}


DASH_V: {
    my @expected = (
        'Well, my daddy left home when I was three',
    );

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( Sue! -1 -h -v --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first non-match' );
}

DASH_F: {
    my @files = qw( t/swamp );
    my @args = qw( -1 -f );
    my @results = run_ack( @args, @files );
    my $test_path = File::Next::reslash( 't/swamp/' );

    is( scalar @results, 1, 'Should only get one file back' );
    like( $results[0], qr{^\Q$test_path\E}, 'One of the files from the swamp' );
}


DASH_G: {
    my $regex = 'Makefile';
    my @files = qw( t/ );
    my @args = ( '-1', '-g', $regex );
    my @results = run_ack( @args, @files );
    my $test_path = File::Next::reslash( 't/swamp/Makefile' );

    is( scalar @results, 1, "Should only get one file back from $regex" );
    like( $results[0], qr{^\Q$test_path\E(\.PL)?$}, 'The one file matches one of the two Makefile files' );
}
