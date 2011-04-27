use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Image::PNG::FileConvert',
    # Where to get the module's version information
    VERSION_FROM => 'lib/Image/PNG/FileConvert.pm',
    # Modules which this depends on
    PREREQ_PM => {
        'Image::PNG' => 0.03,
    },
    # Executable files (scripts) to be installed
    EXE_FILES => [
        'script/file2png',
        'script/png2file',
    ],
    LICENSE => 'perl',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
);

