#!perl -w

use warnings;
use strict;

use Test::More tests => 4;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;
use File::Next ();

my @files = qw(
    t/swamp/options.pl
    t/swamp/options.pl.bak
);

$_ = File::Next::reslash($_) for @files;

JUST_THE_DIR: {
    my @expected = split( /\n/, <<"EOF" );
$files[0]:19:notawordhere
EOF

    my @files = qw( t/swamp );
    my @args = qw( notaword );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, q{One hit for specifying a dir} );
}


SPECIFYING_A_BAK_FILE: {
    my @expected = split( /\n/, <<"EOF" );
$files[0]:19:notawordhere
$files[1]:19:notawordhere
EOF

    my @files = qw( t/swamp/options.pl t/swamp/options.pl.bak );
    my @args = qw( notaword );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, q{Two hits for specifying the file} );
}

FILE_NOT_THERE: {
    my $file = File::Next::reslash( 't/swamp/perl.pod' );

    my @expected_stderr = split( /\n/, <<'EOF' );
ack-standalone: non-existent-file.txt: No such file or directory
EOF

    my @expected_stdout = split( /\n/, <<"EOF" );
${file}:3:=head2 There's important stuff in here!
EOF

    my @files = ( 'non-existent-file.txt', $file );
    my @args = qw( head2 );
    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );

    lists_match( $stderr, \@expected_stderr, q{Error if there's no file} );
    lists_match( $stdout, \@expected_stdout, 'Find the one file that has a hit' );
}
