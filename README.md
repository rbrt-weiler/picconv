# picconv.rb

A Ruby script for creating HTML thumbnail galleries.

## Description

picconv can be used to create a HTML thumbnail gallery out of a directory containing images of any type. You only have to provide an input and an output directory, while picconv takes care of everything else. However, you may provide more options to get a customized output.

## Requirements

picconv requires a [Ruby](https://www.ruby-lang.org/) interpreter, the standard UNIX tool `file` and the tool `convert` from the [ImageMagick](https://imagemagick.org/) package. If the option `--use-exif` is used, the standard UNIX tool `grep` and the program [exif](https://sourceforge.net/projects/libexif/) are also required.

picconv has been tested under Linux only, with Ruby 1.8 and 2.5.5.

## Usage

`./picconv.rb --help`:

```text
USAGE
./picconv.rb [OPTIONS]

ARGUMENT TYPES
STRING
    A free-form string. May be surrounded by ' or ".
INT
    An integer value.
DIR
    Like STRING, but represents an exisiting directory.
SIZE
    A string in the form "INTxINT", i.e. "500x500".
HEXCOL
    A hexadecimal color value, i.e. "#123456" or "#abcdef".

REQUIRED ARGUMENTS
--in-dir DIR
    Directory where the original images reside.
--out-dir DIR
    Output directory for newly created files.

OPTIONAL ARGUMENTS
--im-size SIZE
    Size for newly created fullsize images. Default: "640x640".
--im-qual INT
    Quality for newly created fullsize images. Default: "80".
--im-prefix STRING
    Prefix for newly created fullsize images. Default: "".
--im-suffix STRING
    Suffix for newly created fullsize images. Default: "".
--tn-size SIZE
    Size for newly created thumbnail images. Default: "0".
--tn-qual INT
    Quality for newly created thumbnail images. Default: "40".
--tn-prefix STRING
    Prefix for newly created thumbnail images. Default: "tn_".
--tn-suffix STRING
    Suffix for newly created thumbnail images. Default: "".
--gal-file STRING
    Filename for the HTML file. Default: "index.html".
--gal-title STRING
    Title for the HTML gallery. Default: "HTML Thumbnail Gallery".
--gal-desc STRING
    Description for the gallery. Will be enclosed by p tags. Default: "".
--gal-pprow INT
    Pictures per row in the HTML gallery. Default: "5".
--gal-gzip INT
    Defines if the gallery file should be compressed. Default: "0".
--col-bg HEXCOL
    Specifies the background color. Default: "#cccccc".
--col-text HEXCOL
    Specifies the text color. Default: "#000000".
--col-link HEXCOL
    Specifies the color of unvisited links. Default: "#0000ff".
--col-alink HEXCOL
    Specifies the color of active links. Default: "#ff0000".
--col-vlink HEXCOL
    Specifies the color of visited links. Default: "#990099".
--comment STRING
    Adds the given string to the comment field in the image.
--interlace | --interlaced | --progressive
    Creates interlaced images.
--use-exif
    Fetches EXIF datetime information and displays it in the gallery.
--use-names
    Use original names for newly created images instead of numbering.
--no-convert
    Disables conversion of original images.
--conv-opts STRING
    Additional options for convert.
--conv-opts-fs STRING
    Additional options for convert (fullsize images only).
--conv-opts-tn STRING
    Additional options for convert (thumbnail images only).
--quiet
    Surpresses all messages going to STDOUT.

Please note that picconv will overwrite files in --out-dir.
```

## Exit Codes

| Code | Meaning |
| ---:|:--- |
| 0 | Script finished without any errors. |
| 1 | Usage message shown. |
| 10 | No in-dir supplied. |
| 11 | in-dir is not a directory. |
| 12 | in-dir is not readable. |
| 15 | No out-dir supplied. |
| 16 | out-dir is not a directory. |
| 17 | out-dir is not writable. |
| 20 | Equal prefixes / suffixes. |
| 255 | An unknown / undefined error occured. |

## Source

The original project is [hosted at GitLab](https://gitlab.com/rbrt-weiler/picconv), with a [copy over at GitHub](https://github.com/rbrt-weiler/picconv) for the folks over there.
