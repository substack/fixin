#!/usr/bin/env perl
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
    $re = $comments{ $sh[0] eq "env" ? $sh[1] : $sh[0] }
        // $re;
}

print "re=$re\n";

untie @file;
