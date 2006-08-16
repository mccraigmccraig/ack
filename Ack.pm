package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.24

=cut

our $VERSION = '1.24';

=head1 SYNOPSIS

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 is_filetype( $filename, $filetype )

Asks whether I<$filename> is of type I<$filetype>.

=cut

sub is_filetype {
    my $filename = shift;
    my $wanted_type = shift;

    for my $maybe_type ( filetypes( $filename ) ) {
        return 1 if $maybe_type eq $wanted_type;
    }

    return;
}

our %types;
our %mappings = (
    cc          => [qw( c h )],
    css         => [qw( css )],
    javascript  => [qw( js )],
    parrot      => [qw( pir pasm pmc ops pod pg tg )],
    perl        => [qw( pl pm pod tt ttml t )],
    php         => [qw( php phpt htm html )],
    python      => [qw( py )],
    ruby        => [qw( rb )],
    shell       => [qw( sh bash csh ksh zsh )],
    sql         => [qw( sql ctl )],
    yaml        => [qw( yaml )],
);

sub _init_types {
    while ( my ($type,$exts) = each %mappings ) {
        for my $ext ( @$exts ) {
            push( @{$types{$ext}}, $type );
        }
    }

    return;
}


=head2 filetypes( $filename )

Returns a list of types that I<$filename> could be.  For example, a file
F<foo.pod> could be "perl" or "parrot".

=cut

sub filetypes {
    my $filename = shift;

    _init_types() unless keys %types;

    if ( $filename =~ /\.([^.]+)$/ ) {
        my $ref = $types{lc $1};
        return $ref ? @$ref : ();
    }

    # No extension?  See if it has a shebang line
    if ( $filename !~ /\./ ) {
        my $fh;
        if ( !open( $fh, '<', $filename ) ) {
            warn "ack: $filename: $!\n";
            return;
        }
        my $header = <$fh>;
        close $fh;
        return unless defined $header;
        return 'perl'   if $header =~ /^#!.+\bperl\b/;
        return 'php'    if $header =~ /^#!.+\bphp\b/;
        return 'python' if $header =~ /^#!.+\bpython\b/;
        return 'ruby'   if $header =~ /^#!.+\bruby\b/;
        return 'shell'  if $header =~ /^#!.+\b(ba|c|k|z)?sh\b/;
        return;
    }

    return;
}

=head2 filetypes_supported()

Returns a list of all the types that we can detect.

=cut

sub filetypes_supported {
    return keys %mappings;
}

=head2 interesting_files( \&is_interesting, $should_descend, @starting points )

Returns an iterator that walks directories starting with the items
in I<@starting_points>.  If I<$should_descend> is false, don't descend
into subdirectories. Each file to see if it's interesting is passed to
I<is_interesting>, which must return true.

All file-finding in this module is adapted from Mark Jason Dominus'
marvelous I<Higher Order Perl>, page 126.

=cut

sub interesting_files {
    my $is_interesting = shift;
    my $should_descend = shift;
    my @queue = map { _candidate_files($_) } @_;

    return sub {
        while (@queue) {
            my $file = shift @queue;

            if (-d $file) {
                push( @queue, _candidate_files( $file ) ) if $should_descend;
            }
            elsif (-f $file) {
                return $file if $is_interesting->($file);
            }
        } # while
        return;
    }; # iterator
}

=head2 _candidate_files( $dir )

Pulls out the files/dirs that might be worth looking into in I<$dir>.
If I<$dir> is the empty string, then search the current directory.
This is different than explicitly passing in a ".", because that
will get prepended to the path names.

=cut

our %ignore_dirs = map { ($_,1) } qw( . .. CVS RCS .svn _darcs blib );
sub _candidate_files {
    my $dir = shift;

    my @newfiles;

    # TODO Refactor out the redundancy
    if ( $dir eq '' ) {
        my $dh;
        if ( !opendir $dh, "." ) {
            warn "ack: in current directory: $!\n";
            return;
        }

        @newfiles = grep { !$ignore_dirs{$_} } readdir $dh;
    }
    else {
        return $dir unless -d $dir;

        my $dh;
        if ( !opendir $dh, $dir ) {
            warn "ack: $dir: $!\n";
            return;
        }

        @newfiles = grep { !$ignore_dirs{$_} } readdir $dh;
        @newfiles = map { "$dir/$_" } @newfiles;
    }
    return @newfiles;
}

sub _thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;
    print "$y ack $_[0]!\n";
    exit 0;
}

=head2 show_help()

Dumps the help page to the user.

=cut

sub show_help {
    my @lines = <DATA>;

    for ( @lines ) {
        s/(\w+)(\s+)LIST/$1.$2._expand_list($1)/esmx;
    }
    print @lines;

    return;
}

sub _expand_list {
    my $lang = shift;

    my @files = map { ".$_" } @{$mappings{$lang}};
    my $and = pop @files;

    return @files ? join( ', ', @files ) . " and $and" : $and;
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ack at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ack>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

The App::Ack module isn't very interesting to users.  However, you may
find useful information about this distribution at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ack>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ack>

=item * Search CPAN

L<http://search.cpan.org/dist/ack>

=item * Subversion repository

L<http://ack.googlecode.com/svn/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005-2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Ack

__DATA__
Usage: ack [OPTION]... PATTERN [FILES]
Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
ack may also search STDIN, but only if no FILES are specified, or if
one of FILES is "-".

Default switches may be specified in ACK_SWITCHES environment variable.

Example: ack -i select

Searching:
    -i                ignore case distinctions
    -v                invert match: select non-matching lines
    -w                force PATTERN to match only whole words

Search output:
    -l                only print filenames containing matches
    -o                show only the part of a line matching PATTERN
    -m=NUM            stop after NUM matches
    -H                print the filename for each match
    -h                suppress the prefixing filename on output
    -c, --count       show number of lines matching per file
    --[no]group       print a blank line between each file's matches
                      (default: on unless output is redirected)
    --[no]color       highlight the matching text (default: on unless
                      output is redirected, or on Windows)

File finding:
    -f                only print the files found, without searching.
                      The PATTERN must not be specified.

File inclusion/exclusion:
    -n                No descending into subdirectories
    -a, --all         All files, regardless of extension
                      (but still skips RCS, CVS, .svn, _darcs and blib dirs)
    --[no]cc          LIST
    --[no]javascript  LIST
    --[no]js          same as --[no]javascript
    --[no]parrot      LIST
    --[no]perl        LIST
    --[no]php         LIST
    --[no]python      LIST
    --[no]ruby        LIST
    --[no]shell       LIST
    --[no]sql         LIST
    --[no]yaml        LIST

Miscellaneous:
    --help            this help
    --version         display version
    --thpppt          Bill the Cat


GOTCHAS:
Note that FILES must still match valid selection rules.  For example,

    ack something --perl foo.rb

will search nothing, because foo.rb is a Ruby file.
