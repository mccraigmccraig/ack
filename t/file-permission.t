#!perl

use warnings;
use strict;

use Test::More;

use lib 't';
use Util;

use constant NTESTS => 10;

plan skip_all => q{Can't be checked under Win32} if is_win32;
plan tests => NTESTS;

prep_environment();

my $program = $0;

# change permissions of this file to unreadable
my $old_mode;
(undef, undef, $old_mode) = stat($program);
my $nchanged = chmod 0000, $program;

SKIP: {
    skip q{Unable to modify test program's permissions}, NTESTS unless $nchanged;

    is( $nchanged, 1, sprintf( 'chmodded %s to 0000 from %o', $program, $old_mode ) );

    # execute a search on this file
    check_with( 'regex', $program );

    # --count takes a different execution path
    check_with( 'regex', '--count', $program );

    # change permissions back
    chmod $old_mode, $program;
    is( $nchanged, 1, sprintf( 'chmodded %s back to %o', $program, $old_mode ) );
}

sub check_with {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($stdout, $stderr) = run_ack_with_stderr( @_ );
    is( $?,                0, 'Search normal: exit code zero' );
    is( scalar @{$stdout}, 0, 'Search normal: no normal output' );
    is( scalar @{$stderr}, 1, 'Search normal: one line of stderr output' );
    # don't check for exact text of warning, the message text depends on LC_MESSAGES
    like( $stderr->[0], qr/file-permission\.t:/, 'Search normal: warning message ok' );
}
