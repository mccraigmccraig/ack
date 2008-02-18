#!perl

use warnings;
use strict;

use Test::More tests => 22;

use lib 't';
use Util;

my @files_mentioning_apples = qw(
    t/swamp/groceries/fruit
    t/swamp/groceries/junk
    t/swamp/groceries/another_subdir/fruit
    t/swamp/groceries/another_subdir/junk
    t/swamp/groceries/another_subdir/CVS/fruit
    t/swamp/groceries/another_subdir/CVS/junk
    t/swamp/groceries/another_subdir/RCS/fruit
    t/swamp/groceries/another_subdir/RCS/junk
    t/swamp/groceries/subdir/fruit
    t/swamp/groceries/subdir/junk
    t/swamp/groceries/CVS/fruit
    t/swamp/groceries/CVS/junk
    t/swamp/groceries/RCS/fruit
    t/swamp/groceries/RCS/junk
);
my @std_ignore = qw( RCS CVS );

my( @expected, @results, $test_description );

sub settup_assertion_that_these_options_will_ignore_those_directories {
    my( $options, $ignored_directories, $optional_test_description ) = @_;
    $test_description = $optional_test_description || join( ' ', @$options );

    my $filter = join( '|', @$ignored_directories );
    @expected = grep { ! m{/(?:$filter)/} } @files_mentioning_apples;

    @results = run_ack( @$options, '--noenv', '-la', 'apple', 't/swamp' );
}

FILES_HAVE_BEEN_SET_UP_AS_EXPECTED: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '-u',  ],
        [        ],
        'test data contents are as expected',
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_IGNORE_DIR: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--ignore-dir=subdir',  ],
        [ @std_ignore, 'subdir',  ],
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_IGNORE_DIR_MULTIPLE_TIMES: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--ignore-dir=subdir', '--ignore-dir=another_subdir', ],
        [ @std_ignore, 'subdir',              'another_subdir', ],
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_NOIGNORE_DIR: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--noignore-dir=CVS', ],
        [ 'RCS',                ],
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_NOIGNORE_DIR_MULTIPLE_TIMES: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--noignore-dir=CVS', '--noignore-dir=RCS', ],
        [                                             ],
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_IGNORE_DIR_WITH_DASH_NOIGNORE_DIR: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--noignore-dir=CVS', '--ignore-dir=subdir', ],
        [ 'RCS',                             'subdir', ],
    );
    sets_match( \@results, \@expected, $test_description );
}

LAST_ONE_LISTED_WINS: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--noignore-dir=CVS', '--ignore-dir=CVS', ],
        [ @std_ignore,                              ],
    );
    sets_match( \@results, \@expected, $test_description );

    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--noignore-dir=CVS', '--ignore-dir=CVS', '--noignore-dir=CVS', ],
        [ 'RCS',                                                          ],
    );
    sets_match( \@results, \@expected, $test_description );

    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--ignore-dir=subdir', '--noignore-dir=subdir', ],
        [ @std_ignore,                                    ],
    );
    sets_match( \@results, \@expected, $test_description );

    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '--ignore-dir=subdir', '--noignore-dir=subdir', '--ignore-dir=subdir', ],
        [ @std_ignore,                                                 'subdir', ],
    );
    sets_match( \@results, \@expected, $test_description );
}

DASH_U_BEATS_THE_PANTS_OFF_IGNORE_DIR_ANY_DAY_OF_THE_WEEK: {
    settup_assertion_that_these_options_will_ignore_those_directories(
        [ '-u', '--ignore-dir=subdir', ],
        [                              ],
    );
    sets_match( \@results, \@expected, $test_description );
}
