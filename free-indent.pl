#!/usr/bin/env perl
# James Halliday (http://substack.net)
# vim:ts=4:sw=4:tw=80:et
use warnings;
use strict;

use 5.10.0;
use Getopt::Casual;

my $usage = "Usage:
    $0 --git-add patterns
    $0 --git-rm patterns
    $0 --git-ls, $0 --git-list
    $0 --git-config
        
        Configure a git repository to filter patters
        Must be within a git directory hierarchy.
        
        Examples:
            $0 --git-add *.js *.pl
            $0 --git-rm *.c blarg.c
    
    $0 ( --convert | --restore ) OPTIONS ( file | - )
        
        Convert and restore files with vi modelines to your preferred
        indentation style and back to the original formatting.
        For now, it only converts leading whitespace.
    
        Where OPTIONS are:
            --vimrc=file - the location of the vimrc file to use
                default: \$HOME/.vimrc
            --et, --expandtab - expand tab preference; overrides vimrc
            --ts, --tabstop - tab stop preference; overrides vimrc
";

if (grep /^--git-/, keys %ARGV) {
    use Cwd qw/getcwd/;
    chdir ".." until -d ".git" or getcwd eq "/";
    getcwd ne "/" or die "Not in a git project directory\n";
    
    tie my @attrs, "Tie::File", ".git/info/attributes"
        or die "Couldn't open .git/info/attributes: $!";
    
    if ($ARGV{"--git-ls"} or $ARGV{"--git-list"}) {
        print "$_\n" for grep defined, map m{
            ^ (\S+) \s+ filter=free-indent
        }x, @attrs;
    }
    elsif ($ARGV{"--git-add"}) {
        for my $pat (grep { $_ ne "1" } @ARGV) {
            push @attrs, "$pat filter=free-indent";
        }
    }
    elsif ($ARGV{"--git-rm"}) {
        @attrs = grep {
            if (my ($pat) = $_ =~ m/^(\S+) \s+ filter=free-indent/) {
                grep { $_ ne "1" and $_ eq $pat } @ARGV;
            }
            else {
                undef
            }
        } @attrs;
    }
    elsif ($ARGV{"--git-config"}) {
        system qq{ git config --global filter.free-indent.smudge '$0 --convert' };
        system qq{ git config --global filter.free-indent.clean '$0 --restore' };
    }
    
    untie @attrs;
    exit;
}

$ARGV{"--convert"} or $ARGV{"--restore"} or die $usage;
$ARGV{"--vimrc"} //= "$ENV{HOME}/.vimrc";

use Tie::File;
my $filename = shift // "-";

my @file;
if ($filename eq "-") {
    @file = <>;
}
else {
    tie @file, 'Tie::File', $filename
        or die "Couldn't open '$filename' failed: $!";
}

@file or exit; # don't mess with empty files

# Formatting for modelines is documented here:
# http://vimdoc.sourceforge.net/htmldoc/options.html#auto-setting
# [text]{white}{vi:|vim:|ex:}[white]se[t] {options}:[text]
# [text]{white}{vi:|vim:|ex:}[white]{options}

my $re = qr{
    \s+ (?: vi | vim | ex ) : \s?
    (?: (?: set | se\  ) (.+) : | (.+) )
}x;

my %modes;
for my $opts (grep defined, map $_ =~ $re, grep defined, @file[0..4]) {
    if (my @params = split m/(?<! \\) [:\ ] \s* (?: set \s*)? /x, $opts) {
        %modes = map {
            if (m/(?<! \\) = /x) {
                m/([^=]+)=(.+)/ # assignment
            }
            else {
                (my $flag = $_) =~ s/^no//;
                $flag => m/^no/ ? 0 : 1 # boolean flags
            }
        } @params;
        last;
    }
}
%modes || do {
    # only process when modeline is found
    print for grep defined, @file;
    exit;
};

# short-form aliases
$modes{tabstop} //= $modes{ts} // 8;
$modes{expandtab} //= $modes{et} // 0;
$ARGV{"--expandtab"} //= $ARGV{"--et"};
$ARGV{"--tabstop"} //= $ARGV{"--ts"};

my %prefs;

unless (defined $ARGV{"--expandtab"} and defined $ARGV{"--tabstop"}) {
    tie my @vimrc, "Tie::File", $ARGV{"--vimrc"} or die "Couldn't open vimrc: $!";
    %prefs = map {
        if (m/(?<! \\) =/x) {
            m/([^=]+)=(.+)/ # assignment
        }
        else {
            (my $flag = $_) =~ s/^no//;
            $flag => m/^no/ ? 0 : 1 # boolean flags
        }
    } grep defined, map m/^set \s+ (.+)/x, @vimrc;
    untie @vimrc;
}

$prefs{expandtab} = $ARGV{"--expandtab"} // $prefs{expandtab} // $prefs{et};
$prefs{tabstop} = $ARGV{"--tabstop"} // $prefs{tabstop} // $prefs{ts};

if ($prefs{expandtab} == $modes{expandtab}
and $prefs{tabstop} == $modes{tabstop}) {
    print for grep defined, @file;
    exit;
}

if ($ARGV{"--restore"}) {
    # convert backwards for resets
    my $prefs_r = { %prefs };
    my $modes_r = { %modes };
    %modes = %$prefs_r;
    %prefs = %$modes_r;
}

(tied @file)->defer if $filename ne "-";
for my $line (grep defined, @file) {
    if ($prefs{expandtab}) {
        my $mspaces = " " x $modes{tabstop};
        my $pspaces = " " x $prefs{tabstop};
        
        1 while $line =~ s/^(\s*?)\t/$1$mspaces/;
        
        $line =~ s[^((?:$mspaces)+)]
            [ " "x ((length $1) * $prefs{tabstop} / $modes{tabstop}) ]e;
    }
    else {
        my $spaces = " " x $prefs{tabstop};
        1 while $line =~ s/^(\s*?)$spaces/$1\t/
    }
}
(tied @file)->flush if $filename ne "-";

if ($filename eq "-") {
    print for grep defined, @file;
}
else {
    untie @file;
}
