use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Image/PNG/FileConvert.pm';
my $repo = 'https://github.com/benkasminbullock/Image-PNG-FileConvert';

WriteMakefile (
    NAME => 'Image::PNG::FileConvert',
    # Where to get the module's version information
    VERSION_FROM => $pm,
    # Where the file abstract is.
    ABSTRACT_FROM => $pm,
    # Modules which this depends on
    PREREQ_PM => {
        'Image::PNG' => '0.10',
    },
    # Executable files (scripts) to be installed
    EXE_FILES => [
        'script/file2png',
        'script/png2file',
    ],
    LICENSE => 'perl',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        }
    },    
);

