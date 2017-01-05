#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Template;
use FindBin '$Bin';
use Perl::Build qw/get_commit get_info/;
use Perl::Build::Pod ':all';
use Deploy qw/do_system older/;
use Getopt::Long;
use lib 'lib';
use Image::PNG::FileConvert;
my $ok = GetOptions (
    'force' => \my $force,
    'verbose' => \my $verbose,
);
if (! $ok) {
    usage ();
    exit;
}
my %pbv = (
    base => $Bin,
    verbose => $verbose,
);
my $commit = get_commit (%pbv);
my $info = get_info (%pbv);
# Names of the input and output files containing the documentation.

my $pod = 'FileConvert.pod';
my $input = "$Bin/lib/Image/PNG/$pod.tmpl";
my $output = "$Bin/lib/Image/PNG/$pod";

# Template toolkit variable holder

my %vars = (
    commit => $commit,
    info => $info,
    default_row_length => Image::PNG::FileConvert::default_row_length,
    module => 'Image::PNG::FileConvert',
);

my $tt = Template->new (
    ABSOLUTE => 1,
    INCLUDE_PATH => [
	$Bin,
	pbtmpl (),
	"$Bin/examples",
    ],
    ENCODING => 'UTF8',
    FILTERS => {
        xtidy => [
            \& xtidy,
            0,
        ],
    },
    STRICT => 1,
);

my $example_dir = "$Bin/examples";
my @examples = <$example_dir/*.pl>;
for my $example (@examples) {
    my $output = $example;
    $output =~ s/\.pl$/-out.txt/;
    if (older ($output, $example) || $force) {
	my $file = $example;
	$file =~ s!.*/!!;
	do_system ("chdir $example_dir;make clean;perl -I$Bin/blib/lib -I$Bin/blib/arch $file > $output 2>&1", $verbose);
    }
}

chmod 0644, $output;
$tt->process ($input, \%vars, $output, binmode => 'utf8')
    or die '' . $tt->error ();
chmod 0444, $output;

exit;

sub usage
{
    print <<USAGEEOF;
--verbose
--force
USAGEEOF
}

