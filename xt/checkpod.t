use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Perl::Build::Pod ':all';
my @files = (
    "$Bin/../lib/Image/PNG/FileConvert.pod",
);

for my $filepath (@files) {
    my $errors = pod_checker ($filepath);
    ok (@$errors == 0, "No errors");
    ok (pod_encoding_ok ($filepath), "Pod encoding OK");
    ok (pod_no_cut ($filepath), "No stray =cut in POD");
}
done_testing ();
