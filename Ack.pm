package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.65_01

=cut

our $VERSION;
our $COPYRIGHT;
BEGIN {
    $VERSION = '1.65_01';
    $COPYRIGHT = 'Copyright 2005-2007 Andy Lester, all rights reserved.';
}

our %types;
our %mappings;
our %ignore_dirs;
our $path_sep;
our $is_cygwin;
our $is_windows;
our %type_wanted;

use File::Spec ();
use Getopt::Long ();

BEGIN {
    %ignore_dirs = (
        '.git'  => 'Git',
        '.pc'   => 'quilt',
        '.svn'  => 'Subversion',
        CVS     => 'CVS',
        RCS     => 'RCS',
        SCCS    => 'SCCS',
        _darcs  => 'darcs',
        blib    => 'Perl module building',
    );

    %mappings = (
        asm         => [qw( s )],
        binary      => q{Binary files, as defined by Perl's -B op (default: off)},
        cc          => [qw( c h xs )],
        cpp         => [qw( cpp m h )],
        csharp      => [qw( cs )],
        css         => [qw( css )],
        elisp       => [qw( el )],
        fortran     => [qw( f f77 f90 f95 f03 for ftn fpp )],
        haskell     => [qw( hs lhs )],
        hh          => [qw( h )],
        html        => [qw( htm html shtml )],
        skipped     => q{Files, but not directories, normally skipped by ack (default: off)},
        lisp        => [qw( lisp )],
        java        => [qw( java properties )],
        js          => [qw( js )],
        jsp         => [qw( jsp jspx jhtm jhtml )],
        make        => q{Makefiles},
        mason       => [qw( mas mhtml mpl mtxt )],
        ocaml       => [qw( ml mli )],
        parrot      => [qw( pir pasm pmc ops pod pg tg )],
        perl        => [qw( pl pm pod t )],
        php         => [qw( php phpt php3 php4 php5 )],
        python      => [qw( py )],
        ruby        => [qw( rb rhtml rjs rxml )],
        scheme      => [qw( scm )],
        shell       => [qw( sh bash csh ksh zsh )],
        sql         => [qw( sql ctl )],
        tcl         => [qw( tcl )],
        tex         => [qw( tex cls sty )],
        text        => q{Text files, as defined by Perl's -T op (default: off)},
        tt          => [qw( tt tt2 ttml )],
        vb          => [qw( bas cls frm ctl vb resx )],
        vim         => [qw( vim )],
        yaml        => [qw( yaml yml )],
        xml         => [qw( xml dtd xslt )],
    );

    $path_sep = File::Spec->catfile( '', '' );
    $path_sep = quotemeta( $path_sep );

    while ( my ($type,$exts) = each %mappings ) {
        if ( ref $exts ) {
            for my $ext ( @{$exts} ) {
                push( @{$types{$ext}}, $type );
            }
        }
    }

    $is_cygwin = ($^O eq 'cygwin');
}

=head1 SYNOPSIS

If you want to know about the F<ack> program, see the F<ack> file itself.

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 get_command_line_options()

=cut

sub get_command_line_options {
    my %opt;

    my $getopt_specs = {
        1                       => \$opt{1},
        a                       => \$opt{all},
        'all!'                  => \$opt{all},
        c                       => \$opt{count},
        'color!'                => \$opt{color},
        count                   => \$opt{count},
        f                       => \$opt{f},
        'g=s'                   => \$opt{g},
        'follow!'               => \$opt{follow},
        'group!'                => \$opt{group},
        h                       => \$opt{h},
        H                       => \$opt{H},
        'i|ignore-case'         => \$opt{i},
        'l|files-with-matches'  => \$opt{l},
        'L|files-without-match' => \$opt{L},
        'm|max-count=i'         => \$opt{m},
        n                       => \$opt{n},
        o                       => \$opt{o},
        'output=s'              => \$opt{output},
        'passthru'              => \$opt{passthru},
        'Q|literal'             => \$opt{Q},
        'sort-files'            => \$opt{sort_files},
        'v|invert-match'        => \$opt{v},
        'w|word-regexp'         => \$opt{w},


        'version'   => sub { App::Ack::print_version_statement(); exit 1; },
        'help|?:s'  => sub { shift; App::Ack::show_help(@_); exit; },
        'help-types'=> sub { App::Ack::show_help_types(); exit; },
        'man'       => sub {require Pod::Usage; Pod::Usage::pod2usage({-verbose => 2}); exit; },

        'type=s'    => sub {
            # Whatever --type=xxx they specify, set it manually in the hash
            my $dummy = shift;
            my $type = shift;
            my $wanted = ($type =~ s/^no//) ? 0 : 1; # must not be undef later

            if ( exists $App::Ack::type_wanted{ $type } ) {
                $App::Ack::type_wanted{ $type } = $wanted;
            }
            else {
                App::Ack::die( qq{Unknown --type "$type"} );
            }
        }, # type sub
    };

    my @filetypes_supported = App::Ack::filetypes_supported();
    for my $i ( @filetypes_supported ) {
        $getopt_specs->{ "$i!" } = \$App::Ack::type_wanted{ $i };
    }

    # Stick any default switches at the beginning, so they can be overridden
    # by the command line switches.
    unshift @ARGV, split( ' ', $ENV{ACK_OPTIONS} ) if defined $ENV{ACK_OPTIONS};

    Getopt::Long::Configure( 'bundling', 'no_ignore_case' );
    Getopt::Long::GetOptions( %{$getopt_specs} ) && App::Ack::options_sanity_check( %opt ) or
        App::Ack::die( 'See ack --help or ack --man for options.' );

    $opt{is_filter} = !-t STDIN;

    # Handle new -L the old way: as -l and -v
    if ( $opt{L} ) {
        $opt{l} = $opt{v} = 1;
    }

    # Make the -m do work for us if we have -1
    if ( $opt{1} ) {
        $opt{m} = 1;
    }

    App::Ack::apply_defaults(\%opt);

    # XXX This can get simplified
    if ( $opt{o} ) {
        $opt{output} = eval qq[ sub { $& } ];
    }

    if ( defined( my $val = $opt{output} ) ) {
        $val = qq{"$val"};
        $opt{output} = eval qq[ sub { $val } ];
    }

    return %opt;
}

=head2 skipdir_filter

Standard filter to pass as a L<File::Next> descend_filter.  It
returns true if the directory is any of the ones we know we want
to skip.

=cut

sub skipdir_filter {
    return !exists $ignore_dirs{$_};
}

=head2 filetypes( $filename )

Returns a list of types that I<$filename> could be.  For example, a file
F<foo.pod> could be "perl" or "parrot".

The filetype will be C<undef> if we can't determine it.  This could
be if the file doesn't exist, or it can't be read.

It will be 'skipped' if it's something that ack should always ignore,
even under -a.

=cut

use constant TEXT => 'text';

sub filetypes {
    my $filename = shift;

    return 'skipped' unless is_searchable( $filename );

    return ('make',TEXT) if $filename =~ m{$path_sep?Makefile$}io;

    # If there's an extension, look it up
    if ( $filename =~ m{\.([^\.$path_sep]+)$}o ) {
        my $ref = $types{lc $1};
        return (@{$ref},TEXT) if $ref;
    }

    # At this point, we can't tell from just the name.  Now we have to
    # open it and look inside.

    return unless -e $filename;
    # From Elliot Shank:
    #     I can't see any reason that -r would fail on these-- the ACLs look
    #     fine, and no program has any of them open, so the busted Windows
    #     file locking model isn't getting in there.  If I comment the if
    #     statement out, everything works fine
    # So, for cygwin, don't bother trying to check for readability.
    if ( !$is_cygwin ) {
        if ( !-r $filename ) {
            App::Ack::warn( "$filename: Permission denied" );
            return;
        }
    }

    return 'binary' if -B $filename;

    # If there's no extension, or we don't recognize it, check the shebang line
    my $fh;
    if ( !open( $fh, '<', $filename ) ) {
        App::Ack::warn( "$filename: $!" );
        return;
    }
    my $header = <$fh>;
    if ( not close $fh ) {
        App::Ack::warn( "$filename: $!" );
        return;
    }

    if ( $header =~ /^#!/ ) {
        return ($1,TEXT)       if $header =~ /\b(ruby|p(erl|hp|ython))\b/;
        return ('shell','text')  if $header =~ /\b(?:ba|c|k|z)?sh\b/;
    }
    return ('xml',TEXT) if $header =~ /<\?xml /;

    return (TEXT);
}

=head2 is_searchable( $filename )

Returns true if the filename is one that we can search, and false
if it's one that we should ignore like a coredump or a backup file.

=cut

sub is_searchable {
    my $filename = shift;

    return if $filename =~ /~$/;
    return if $filename =~ m{$path_sep?(?:#.+#|core\.\d+)$}o;

    return 1;
}

=head2 options_sanity_check( %opts )

Checks for sane command-line options.  For example, I<-l> doesn't
make sense with I<-C>.

=cut

sub options_sanity_check {
    my %opts = @_;
    my $ok = 1;

    # List mode doesn't make sense with any of these
    $ok = 0 if _option_conflict( \%opts, 'l', [qw( A B C o group )] );

    # XXX This should work, I would think.
    $ok = 0 if _option_conflict( \%opts, 'l', [qw( m )] );

    # File-searching is definitely irrelevant on these
    for my $switch ( qw( f g ) ) {
        $ok = 0 if _option_conflict( \%opts, $switch, [qw( A B C o m group l )] );
    }

    return $ok;
}

sub _option_conflict {
    my $opts = shift;
    my $used = shift;
    my $exclusives = shift;

    return if not defined $opts->{$used};

    my $bad = 0;
    for my $opt ( @{$exclusives} ) {
        if ( defined $opts->{$opt} ) {
            print 'The ', _opty($opt), ' option cannot be used with the ', _opty($used), " option.\n";
            $bad = 1;
        }
    }

    return $bad;
}

sub _opty {
    my $opt = shift;
    return length($opt)>1 ? "--$opt" : "-$opt";
}

=head2 warn( @_ )

Put out an ack-specific warning.

=cut

sub warn { ## no critic (ProhibitBuiltinHomonyms)
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

=head2 die( @_ )

Die in an ack-specific way.

=cut

sub die { ## no critic (ProhibitBuiltinHomonyms)
    return CORE::die( _my_program(), ': ', @_, "\n" );
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}


=head2 filetypes_supported()

Returns a list of all the types that we can detect.

=cut

sub filetypes_supported {
    return keys %mappings;
}

sub _get_thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;
    return $y;
}

sub _thpppt {
    my $y = _get_thpppt();
    print "$y ack $_[0]!\n";
    exit 0;
}

sub _key {
    my $str = lc shift;
    $str =~ s/[^a-z]//g;

    return $str;
}

=head2 show_help()

Dumps the help page to the user.

=cut

sub show_help {
    my $help_arg = shift || 0;

    return show_help_types() if $help_arg =~ /^types?/;

    my $ignore_dirs = _listify( sort { _key($a) cmp _key($b) } keys %ignore_dirs );

    print <<"END_OF_HELP";
Usage: ack [OPTION]... PATTERN [FILES]

Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
ack may also search STDIN, but only if no FILES are specified, or if
one of FILES is "-".

Default switches may be specified in ACK_OPTIONS environment variable.

Example: ack -i select

Searching:
  -i, --ignore-case     Ignore case distinctions
  -v, --invert-match    Invert match: select non-matching lines
  -w, --word-regexp     Force PATTERN to match only whole words
  -Q, --literal         Quote all metacharacters; expr is literal

Search output:
  -l, --files-with-matches
                        Only print filenames containing matches
  -L, --files-without-match
                        Only print filenames with no match
  -o                    Show only the part of a line matching PATTERN
                        (turns off text highlighting)
  --passthru            Print all lines, whether matching or not
  --output=expr         Output the evaluation of expr for each line
                        (turns off text highlighting)
  -m, --max-count=NUM   Stop searching in a file after NUM matches
  -H, --with-filename   Print the filename for each match
  -h, --no-filename     Suppress the prefixing filename on output
  -c, --count           Show number of lines matching per file

  --group               Group matches by file name.
                        (default: on when used interactively)
  --nogroup             One result per line, including filename, like grep
                        (default: on when the output is redirected)

  --[no]color           Highlight the matching text (default: on unless
                        output is redirected, or on Windows)

File finding:
  -f                    Only print the files found, without searching.
                        The PATTERN must not be specified.
  -g=REGEX              Same as -f, but only print files matching REGEX.
  --sort-files          Sort the found files lexically.

File inclusion/exclusion:
  -n                    No descending into subdirectories
  -a, --all             All files, regardless of extension (but still skips
                        $ignore_dirs dirs)
  --perl                Include only Perl files.
  --type=perl           Include only Perl files.
  --noperl              Exclude Perl files.
  --type=noperl         Exclude Perl files.
                        See "ack --help type" for supported filetypes.
  --[no]follow          Follow symlinks.  Default is off.

Miscellaneous:
  --help                This help
  --man                 Man page
  --version             Display version & copyright
  --thpppt              Bill the Cat
END_OF_HELP

    return;
}


=head2 show_help_types()

Display the filetypes help subpage.

=cut

sub show_help_types {
    print <<'END_OF_HELP';
Usage: ack [OPTION]... PATTERN [FILES]

The following is the list of filetypes supported by ack.  You can
specify a file type with the --type=TYPE format, or the --TYPE
format.  For example, both --type=perl and --perl work.

Note that some extensions may appear in multiple types.  For example,
.pod files are both Perl and Parrot.

END_OF_HELP

    my @types = filetypes_supported();
    for my $type ( sort @types ) {
        next if $type =~ /^-/; # Stuff to not show
        my $ext_list = $mappings{$type};

        if ( ref $ext_list ) {
            $ext_list = join( ' ', map { ".$_" } @{$ext_list} );
        }
        printf( "    --[no]%-9.9s %s\n", $type, $ext_list );
    }

    return;
}

sub _listify {
    my @whats = @_;

    return '' if !@whats;

    my $end = pop @whats;
    return @whats ? join( ', ', @whats ) . " and $end" : $end;
}

=head2 get_version_statement( $copyright )

Returns the version information for ack.

=cut

sub get_version_statement {
    my $copyright = get_copyright();
    return <<"END_OF_VERSION";
ack $App::Ack::VERSION

$copyright

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
END_OF_VERSION
}

=head2 print_version_statement( $copyright )

Prints the version information for ack.

=cut

sub print_version_statement {
    print get_version_statement();

    return;
}

=head2 get_copyright 

Return the copyright for ack.

=cut

sub get_copyright {
    return $COPYRIGHT;
}

=head2 load_colors

Set default colors, load Term::ANSIColor on non Windows platforms

=cut

sub load_colors {
    $is_windows = ($^O =~ /MSWin32/);
    eval 'use Term::ANSIColor ();' unless $is_windows;

    $ENV{ACK_COLOR_MATCH}    ||= 'black on_yellow';
    $ENV{ACK_COLOR_FILENAME} ||= 'bold green';

    return;
}

=head2 is_interesting

File type filter, filtering based on the wanted file types

=cut

sub is_interesting {
    return if /^\./;

    my $include;
    my $exclude;

    for my $type ( App::Ack::filetypes( $File::Next::name ) ) {
        if ( defined $App::Ack::type_wanted{$type} ) {
            $include = 1 if $App::Ack::type_wanted{$type};
            $exclude = 1 if not $App::Ack::type_wanted{$type};
        }
    }

    return ( $include && not $exclude );
}

=head2 dash_a_file_filter

File filter for the -a option

=cut

sub dash_a_file_filter {
    return App::Ack::is_searchable( $File::Next::name );
}

sub _search_v {
    my $fh = shift;
    my $is_binary = shift;
    my $filename = shift;
    my $regex = shift;
    my %opt = @_;

    my $nmatches = 0; # Although in here, it's really $n_non_matches. :-)

    my $show_lines = !($opt{l} || $opt{count});
    local $_ = undef;
    while (<$fh>) {
        if ( /$regex/o ) {
            return 0 if $opt{l}; # For list mode, any match means we can bail
            next;
        }
        else {
            ++$nmatches;
            if ( $show_lines ) {
                if ( $is_binary ) {
                    print "Binary file $filename matches\n";
                    last;
                }
                print "${filename}:" if $opt{show_filename};
                print $_;
                last if $opt{m} && ( $nmatches >= $opt{m} );
            }
        }
    } # while
    close $fh or App::Ack::warn( "$filename: $!" );

    if ( $opt{count} ) {
        print "${filename}:" if $opt{show_filename};
        print "${nmatches}\n";
    }
    else {
        print "$filename\n" if $opt{l};
    }

    return $nmatches;
} # _search_v()

=head2 search

Main search method

=cut

sub search {
    my $filename = shift;
    my $regex = shift;
    my %opt = @_;

    my $is_binary;

    my $fh;
    if ( $filename eq '-' ) {
        $fh = *STDIN;
        $is_binary = 0;
    }
    else {
        if ( !open( $fh, '<', $filename ) ) {
            App::Ack::warn( "$filename: $!" );
            return;
        }
        $is_binary = -B $filename;
    }

    # Negated counting is a pain, so I'm putting it in its own
    # optimizable subroutine.
    if ( $opt{v} ) {
        return App::Ack::_search_v( $fh, $is_binary, $filename, $regex, %opt );
    }

    my $nmatches = 0;
    local $_ = undef;
    while (<$fh>) {
        next unless $opt{passthru} || /$regex/o;
        ++$nmatches;
        next if $opt{count}; # Counting means no lines

        # No point in searching more if we only want a list,
        # and don't want a count.
        last if $opt{l};

        if ( $is_binary ) {
            print "Binary file $filename matches\n";
            last;
        }

        my $out;
        if ( $opt{output} ) {
            $out = $opt{output}->() . "\n";
        }
        else {
            $out = $_;
            $out =~ s/($regex)/Term::ANSIColor::colored($1,$ENV{ACK_COLOR_MATCH})/eg if $opt{color};
        }

        if ( $opt{show_filename} ) {
            my $display_filename =
                $opt{color}
                    ? Term::ANSIColor::colored( $filename, $ENV{ACK_COLOR_FILENAME} )
                    : $filename;
            if ( $opt{group} ) {
                print "$display_filename\n" if $nmatches == 1;
                print "$.:";
            }
            else {
                print "${display_filename}:$.:";
            }
        }
        print $out;

        last if $opt{m} && ( $nmatches >= $opt{m} );
    } # while
    close $fh or App::Ack::warn( "$filename: $!" );

    if ( $opt{count} ) {
        if ( $nmatches || !$opt{l} ) {
            print "${filename}:" if $opt{show_filename};
            print "${nmatches}\n";
        }
    }
    elsif ( $opt{l} ) {
        print "$filename\n" if $nmatches;
    }
    else {
        print "\n" if $nmatches && $opt{show_filename} && $opt{group};
    }

    return $nmatches;
}   # search()

=head2 apply_defaults

Apply the default options

=cut

sub apply_defaults {
    my $opt = shift;

    my $to_screen = -t *STDOUT;
    my %defaults = (
        all     => 0,
        color   => $to_screen && !$App::Ack::is_windows,
        follow  => 0,
        group   => $to_screen,
        m       => 0,
    );
    while ( my ($key,$value) = each %defaults ) {
        if ( not defined $opt->{$key} ) {
            $opt->{$key} = $value;
        }
    }

    return;
}

=head2 filetypes_supported_set

True/False - are the filetypes set?

=cut

sub filetypes_supported_set {
    return grep { defined $App::Ack::type_wanted{$_} && ($App::Ack::type_wanted{$_} == 1) } filetypes_supported();
}

=head2 filetypes_supported_unset

True/False - are the filetypes unset?

=cut

sub filetypes_supported_unset {
    return grep { defined $App::Ack::type_wanted{$_} && ($App::Ack::type_wanted{$_} == 0) } filetypes_supported();
}

=head2 print_files( $iter, $one )

Prints all the files returned by the iterator.  If I<$one> is set,
stop after the first.

=cut

sub print_files {
    my ($iter, $one) = @_;
    while ( defined ( my $file = $iter->() ) ) {
        print "$file\n";
        last if $one;
    }

    return;
}

=head2 print_selected_files( $iter, $regex, $one )

Prints all the files returned by the iterator matching I<$regex>.
If I<$one> is set, stop after the first.

=cut

sub print_selected_files {
    my $iter = shift;
    my $regex = shift;
    my $one = shift;

    while ( defined ( my $file = $iter->() ) ) {
        if ( $file =~ m/$regex/o ) {
            print "$file\n";
            last if $one;
        }
    }

    return;
}

1; # End of App::Ack
