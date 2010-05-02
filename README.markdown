Overview
========

fixin
-----

Insulate your superior whitespace preferences from the misguided preferences of
others.

Tabs or spaces? This is the issue of our times, but the controversy doesn't end
there. Among space-advocates, how many spaces? Two? Four? Eight? I've even seen
three. With fixin, you can use whatever indentation scheme you want without
stepping on anybody's toes.

This project uses git filters and ~/.vimrc. It doesn't actually use vim, so you
can use any text editor so long as you've got a ~/.vimrc.

Installation
============
    Put fixin and git-fixin in your $PATH.
    You'll need perl 5.10 or later and Getopt::Casual from cpan.

Example
=======
    git clone git://github.com/substack/fixin.git
    cd fixin
    git-fixin install
    git-fixin add \*ixin
    git checkout

In this example, fixin read your ~/.vimrc and converted all the files that match
*ixin (git-fixin, fixin). Those files have 4-space indentation, so if your
~/.vimrc has a different setting they should be automatically converted.

For now, fixin only looks at expandtab (et) and stoptab (st) settings to do its
calculation, so make sure to set those.

Now, whatever commits you make are treated as though they were written in the
original indentation format. However, files must have modelines to be
automatically converted.

Modelines
=========

Modelines look like this:
    # vim:ts=4:sw=4:tw=80:et

They are found in the first few (usually 5) lines of a file and describe
per-file vim settings to use.

With fixins, you should turn modelines off: set nomodeline.
Fixins uses the modeline to store the original indentation preferences.

If you want files to be automatically handled by fixin, add a modeline for the
original formatting, then:

    fixin file.c

to convert it. Next make the file will be caught by the filter patterns. You can
get a list of what fixin routes are available by typing:

    git-fixin list

If the file isn't in this list,

    git-fixin add \*.c

will do the trick.

After these steps, make commits, merges, pulls, and whatever else as usual.

See Also
========

http://vimdoc.sourceforge.net/htmldoc/options.html#auto-setting

http://stackoverflow.com/questions/2316677/can-git-automatically-switch-between-spaces-and-tabs
