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
            default: ~/.vimrc
        --et, --expandtab - expand tab preference; overrides vimrc
        --ts, --tabstop - tab stop preference; overrides vimrc
";
$ARGV{"--indent"} or $ARGV{"--unindent"} or die $usage;

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

my %set;
for my $opts (grep defined, map $_ =~ $re, grep defined, @file[0..4]) {
    if (my @modes = split m/(?<! \\) [:\ ] \s* (?: set \s*)? /x, $opts) {
        %set = map {
            if (m/(?<! \\) = /x) {
                m/([^=]+)=(.+)/ # assignment
            }
            else {
                (my $flag = $_) =~ s/^no//;
                $flag => m/^no/ ? 0 : 1 # boolean flags
            }
        } @modes;
        last;
    }
}
%set // exit; # only process when modeline is found

# short-form aliases
$set{tabstop} //= $set{ts};
$set{expandtab} //= $set{et};

# vim:ts=4:sw=4:tw=80:et
use Text::Indent;
my $indent = Text::Indent->new(
    SpaceChar => $set{expandtab} ? " " : "\t",
    Spaces => ($set{expandtab} ? $set{tabstop} // 8 : 1),
    AddNewLine => 0,
);

for my $line (@file) {
    # ...
}

untie @file;
