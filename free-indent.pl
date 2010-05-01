#!/usr/bin/env perl
# James Halliday (http://substack.net)
# vim:ts=4:sw=4:tw=80:et
use warnings;
use strict;

use 5.10.0;
use Getopt::Casual;

my $usage = "Usage: $0 ( --convert | --restore ) OPTIONS file
    Convert and restore files with vi modelines to your preferred indentation
    style and back to the original formatting.
    
    Where OPTIONS are:
        --vimrc=file - the location of the vimrc file to use
            default: \$HOME/.vimrc
        --et, --expandtab - expand tab preference; overrides vimrc
        --ts, --tabstop - tab stop preference; overrides vimrc
";
$ARGV{"--convert"} or $ARGV{"--restore"} or die $usage;
$ARGV{"--vimrc"} //= "$ENV{HOME}/.vimrc";

use Tie::File;
my $filename = shift // die $usage;
tie my @file, 'Tie::File', $filename
    or die "Couldn't open '$filename' failed: $!";
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
%modes // exit; # only process when modeline is found

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

exit if $prefs{expandtab} == $modes{expandtab} and $prefs{tabstop} == $modes{tabstop};

if ($ARGV{"--convert"}) {
    for my $line (@file) {
        if ($prefs{expandtab}) {
            my $spaces = " " x $prefs{tabstop};
            $line =~ s/\t/$spaces/g;
        }
    }
}
else { # restore
}

END { untie @file; }
