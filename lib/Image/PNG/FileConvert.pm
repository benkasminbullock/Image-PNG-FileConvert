package Image::PNG::FileConvert;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/file2png png2file/;
use warnings;
use strict;
our $VERSION = 0.05;
use Carp;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

use constant {
    default_row_length => 0x800,
    default_max_rows => 0x800,
};

sub file2png
{
    my ($file, $png_file, $options) = @_;
    if (! -f $file) {
        carp "I can't find '$file'";
        return;
    }
    if (! $png_file) {
        carp "I need a name for the PNG output";
        return;
    }
    if (-f $png_file) {
        carp "Output PNG file '$png_file' already exists";
        return;
    }
    if (! $options) {
        $options = {};
    }
    if (! $options->{row_length}) {
        $options->{row_length} = default_row_length;
    }
    if (! $options->{max_rows}) {
        $options->{max_rows} = default_max_rows;
    }
    my @rows;
    my $bytes = -s $file;
    open my $input, "<:raw", $file;
    my $i = 0;
    my $total_red = 0;
    while (! eof ($input)) {
        my $red = read ($input, $rows[$i], $options->{row_length});
        if ($red != $options->{row_length}) {
            if ($total_red + $red != $bytes) {
                warn "Short read of $red bytes at row $i.\n"
            }
        }
        $total_red += $red;
        $i++;
    }
    close $input;
    if ($options->{verbose}) {
        printf "Read 0x%X rows.\n", $i;
    }

    # Fill the final row up with useless bytes so that we are not
    # reading from unallocated memory.

    # The number of bytes in the last row.
    my $end_bytes = $bytes % $options->{row_length};
    if ($end_bytes > 0) {
        $rows[-1] .= "X" x ($options->{row_length} - $end_bytes);
    }

    # Create the PNG data in a Perl structure.

    my $png = create_write_struct ();
    my %IHDR = (
        width => $options->{row_length},
        height => scalar @rows,
        color_type => PNG_COLOR_TYPE_GRAY,
        bit_depth => 8,
    );
    set_IHDR ($png, \%IHDR);
    set_rows ($png, \@rows);

    # Write the PNG data to a file.

    open my $output, ">:raw", "$png_file";
    init_io ($png, $output);

    # Set the timestamp of the PNG file to the current time.

    set_tIME ($png);
    my $name;
    if ($options->{name}) {
        $name = $options->{name};
    }
    else {
        $name = $file;
    }
    # Put the name and size of the file into the file as text
    # segments.
    set_text ($png, [{key => 'bytes',
                      text => $bytes,
                      compression => PNG_TEXT_COMPRESSION_NONE},
                     {key => 'name',
                      text => $name,
                      compression => PNG_TEXT_COMPRESSION_NONE},
                    ]);
    write_png ($png);
    close $output;
}

sub png2file
{
    my ($png_file, $options) = @_;
    my $me = __PACKAGE__ . "::png2file";
    if (! $png_file) {
        croak "$me: please specify a file";
    }
    if (! -f $png_file) {
        croak "$me: can't find the PNG file '$png_file'";
    }
    if (! defined $options) {
        $options = {};
    }
    open my $input, "<:raw", $png_file;
    my $png = create_read_struct ();
    init_io ($png, $input);
    if ($options->{verbose}) {
        print "Reading file\n";
    }
    read_png ($png);
    my $IHDR = get_IHDR ($png);
    if ($options->{verbose}) {
        print "Getting rows\n";
    }
    my $rows = get_rows ($png);
    if ($options->{verbose}) {
        print "Finished reading file\n";
    }
    close $input;
    my $text_segments = get_text ($png);
    if (! defined $text_segments) {
        croak "$me: the PNG file '$png_file' does not have any text segments, so either it was not created by " . __PACKAGE__ . "::file2png, or it has had its text segments removed";
        return;
    }
    my $name;
    my $bytes;
    for my $text_segment (@$text_segments) {
        if ($text_segment->{key} eq 'name') {
            $name = $text_segment->{text};
        }
        elsif ($text_segment->{key} eq 'bytes') {
            $bytes = $text_segment->{text};
        }
        else {
            carp "Unknown text segment with key '$text_segment->{key}' in '$png_file'";
        }
    }
    if (! $name || ! $bytes) {
        croak "$me: the PNG file '$png_file' does not have information about the file name or the number of bytes of data, so either it was not created by " . __PACKAGE__ . "::file2png, or it has had its text segments removed";
    }
    if ($bytes <= 0) {
        croak "$me: the byte file size $bytes in '$png_file' is impossible";
    }
    my $row_bytes = get_rowbytes ($png);
    if (-f $name) {
        croak "$me: a file with the name '$name' already exists";
    }
    open my $output, ">:raw", $name;
    for my $i (0..$#$rows - 1) {
        print $output $rows->[$i];
    }
    my $final_row = substr ($rows->[-1], 0, $bytes % $row_bytes);
    print $output $final_row;
    close $output;
    return;
}

1;

=head1 NAME

Image::PNG::FileConvert - convert a file to or from a PNG image

=head1 SYNOPSIS

    use Image::PNG::FileConvert qw/file2png png2file/;
    # Convert a data file into a PNG image
    file2png ('myfile.txt', 'myfile.png');
    # Extract a data file from a PNG image
    png2file ('myfile.png');

=head1 FUNCTIONS

=head2 file2png

    file2png ('myfile.txt', 'myfile.png');

Convert C<myfile.txt> into a PNG graphic. The function uses the data
from myfile.txt to write a greyscale (black and white) image. The
bytes of the file correspond to the pixels of the image.

When this PNG is unwrapped using L</png2file>, it will be called
C<myfile.txt> again. If you want to specify a different name,

    file2png ('myfile.txt', 'myfile.png',
              { name => 'not-the-same-name.txt' });

and the file will be unwrapped into C<not-the-same-name.txt>.

If you want your PNG to have a different width than the default, there
is another option, C<row_length>, specified in the same way:

    file2png ('myfile.txt', 'myfile.png', { row_length => 0x100 });

The number you specify for C<row_length> will be the width of the
image in pixels.

=head2 png2file

    png2file ('myfile.png');

Convert C<myfile.png> into a data file. C<myfile.png> must be a PNG
created using L</file2png>. The file is stored in whatever the name of
the file given to L</file2png> was.

Please note that this only converts PNG files output by L</file2png>,
not general PNG files.

=head1 BUGS

=over

=item Holds file in memory

Both the routines here hold the entire file in memory, limiting the
data size which can be converted to or from a PNG.

=item There should be a way to specify the output name in png2file

There should be some option to specify the name of the output file in
L</png2file>.

=back

=head1 WHY?

This module is for people who want to sneakily use free photo/image
sharing websites, free mail services, or other such dumbasseries to
store and retrieve data files.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 LICENCE

You can use, modify and distribute this software under the Perl
Artistic Licence or the GNU General Public Licence.

=head1 DIAGNOSTICS

=head1 SEE ALSO

=over

=item Acme::Steganography::Image::Png

L<Acme::Steganography::Image::Png> I'm not sure what this does, but
maybe it does something similar to Image::PNG::FileConvert.

=back

=head1 UTILITIES

The distribution also includes two utility scripts, file2png and
png2file, which convert a file to a PNG image and back again.

=cut

