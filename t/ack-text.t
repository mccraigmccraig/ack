#!perl

use warnings;
use strict;

use Test::More tests => 1;
use App::Ack ();
use File::Next ();
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;


ACK_F_TEXT: {
    my @expected = qw(
        t/00-load.t
        t/ack-a.t
        t/ack-binary.t
        t/ack-c.t
        t/ack-text.t
        t/ack-type.t
        t/ack-v.t
        t/etc/buttonhook.html.xxx
        t/etc/buttonhook.noxml.xxx
        t/etc/buttonhook.rfc.xxx
        t/etc/buttonhook.rss.xxx
        t/etc/buttonhook.xml.xxx
        t/etc/shebang.foobar.xxx
        t/etc/shebang.php.xxx
        t/etc/shebang.pl.xxx
        t/etc/shebang.py.xxx
        t/etc/shebang.rb.xxx
        t/etc/shebang.sh.xxx
        t/filetypes.t
        t/interesting.t
        t/longopts.t
        t/pod-coverage.t
        t/pod.t
        t/standalone.t
        t/swamp/0
        t/swamp/c-header.h
        t/swamp/c-source.c
        t/swamp/html.htm
        t/swamp/html.html
        t/swamp/javascript.js
        t/swamp/Makefile
        t/swamp/Makefile.PL
        t/swamp/options.pl
        t/swamp/parrot.pir
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/text/boy-named-sue.txt
        t/text/freedom-of-choice.txt
        t/text/science-of-myth.txt
        t/text/shut-up-be-happy.txt
        t/Util.pm
        t/zero.t
    );

    my @files = qw( t );
    my @args = qw( -f --text );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, 'Looking for text files' );
}
