#!perl

use strict;
use warnings;

=head1 DESCRIPTION

This tests whether L<ack(1)>'s command line options work as expected.

=cut

use Test::More qw( no_plan );

my $swamp = 't/swamp';
my $ack   = './ack';

# Help
for ( qw( -h --help ) ) {
    like
        qx{ $^X $ack $_ },
        qr{ ^Usage: .* Example: }xs,
        qq{$_ output is correct};
    option_in_usage( $_ );
}

# Version
for ( qw( --version ) ) {
    like
        qx{ $^X $ack $_ },
        qr{ ^ack .* Copyright .* Perl }xs,
        qq{$_ output is correct};
    option_in_usage( $_ );
}

# Ignore case
for ( qw( -i --ignore-case ) ) {
    like
        qx{ $^X $ack $_ "upper case" t/swamp/options.pl },
        qr{UPPER CASE},
        qq{$_ works correctly for ascii};
    option_in_usage( $_ );
}

# Invert match
for ( qw( -v --invert-match ) ) {
    unlike
        qx{ $^X $ack $_ "use warnings" t/swamp/options.pl },
        qr{use warnings},
        qq{$_ works correctly};
    option_in_usage( $_ );
}

# Word regexp
for ( qw( -w --word-regexp ) ) {
    like
        qx{ $^X $ack $_ "word" t/swamp/options.pl },
        qr{ word },
        qq{$_ ignores non-words};
    unlike
        qx{ $^X $ack $_ "word" t/swamp/options.pl },
        qr{notaword},
        qq{$_ ignores non-words};
    option_in_usage( $_ );
}

# Literal
for ( qw( -Q --literal ) ) {
    like
        qx{ $^X $ack $_ '[abc]' t/swamp/options.pl },
        qr{\Q[abc]\E},
        qq{$_ matches a literal string};
    option_in_usage( $_ );
}

# Files with matches
for ( qw( -l --files-with-matches ) ) {
    like
        qx{ $^X $ack $_ 'use strict' t/swamp/options.pl },
        qr{\Qt/swamp/options.pl},
        qq{$_ prints matching files};
    option_in_usage( $_ );
}

# Files without match
for ( qw( -L --files-without-match ) ) {
    unlike
        qx{ $^X $ack $_ 'use puppies' t/swamp/options.pl },
        qr{\Qt/swamp/options.pl},
        qq{$_ prints matching files};
    option_in_usage( $_ );
}

my $usage;
sub option_in_usage {
    my $opt = shift;

    $usage = qx{ $^X $ack --help } unless $usage;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like( $usage, qr/\Q$opt\E\b/, "Found $opt in usage" );
}
