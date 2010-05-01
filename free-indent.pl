#!/usr/bin/env perl
# James Halliday (http://substack.net)
# vim:ts=4:sw=4:tw=80:et
use warnings;
use strict;

use 5.10.0;
use Text::Indent;
use Language::Functional qw/:all/;
use Tie::File;

my $filename = shift // die "Usage: $0 file";
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
%set // exit;

untie @file;

__END__
my %comments = (
    (map { $_ => qr/^ \s* # \s* (.+)/x } qw/
        perl pl python py bash csh ksh tcsh sh
    /),
    (map { $_ => qr/^ \s* -- \s* (.+)/x } qw/
        runhaskell runghc runhugs hs
    /),
);

use File::Basename qw/basename/;

# guess the comment style based on the file's extension
my $re = $comments{ lc head[ $filename =~ m/\. ([^.]+) $/x ] };

# unless there is a shebang, in which trumps the extension
if (my @sh = map basename($_), split /\s+/, head[ $file[0] =~ m/^#!(.+)/ ]) {
    $re = $comments{ $sh[0] eq "env" ? $sh[1] : $sh[0] } // $re;
}

$re // exit; # don't mess with unknown files
