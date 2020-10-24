#!/usr/bin/ruby -w
# vim: set ts=4 sw=4 sts=4 et ft=ruby fenc=utf-8 ff=unix :

#
# picconv - a script for creating HTML thumbnail galleries.
# (c) 2003-2007,2012,2020 Robert Weiler <https://robert.weiler.one/>
# <https://gitlab.com/rbrt-weiler/picconv>
#

require 'getoptlong'

PICCONV_VERSION = '1.9.6'
PICCONV_URL = 'https://gitlab.com/rbrt-weiler/picconv'

#==========================================================================
# Preparations: Some functions.
#==========================================================================

# generic startup message
def header(quiet = false)
    unless quiet
        puts "picconv #{PICCONV_VERSION} - a script for creating HTML " \
            'thumbnail galleries.'
        puts '(c) 2003-2007,2012,2020 Robert Weiler <https://robert.weiler.one/>'
        puts "Latest version: <#{PICCONV_URL}>"
        puts
        puts 'This script is provided as-is without any guarantee of any ' \
            'kind. Refer to the'
        puts 'MIT license for details.'
        puts
    end
end

# shows the usage message
def usage()
    puts 'USAGE'
    puts "#{$0} [OPTIONS]"
    puts
    puts 'ARGUMENT TYPES'
    puts 'STRING'
    puts '    A free-form string. May be surrounded by \' or ".'
    puts 'INT'
    puts '    An integer value.'
    puts 'DIR'
    puts '    Like STRING, but represents an exisiting directory.'
    puts 'SIZE'
    puts '    A string in the form "INTxINT", i.e. "500x500".'
    puts 'HEXCOL'
    puts '    A hexadecimal color value, i.e. "#123456" or "#abcdef".'
    puts
    puts 'REQUIRED ARGUMENTS'
    puts '--in-dir DIR'
    puts '    Directory where the original images reside.'
    puts '--out-dir DIR'
    puts '    Output directory for newly created files.'
    puts
    puts 'OPTIONAL ARGUMENTS'
    puts '--im-size SIZE'
    puts '    Size for newly created fullsize images. Default: "640x640".'
    puts '--im-qual INT'
    puts '    Quality for newly created fullsize images. Default: "80".'
    puts '--im-prefix STRING'
    puts '    Prefix for newly created fullsize images. Default: "".'
    puts '--im-suffix STRING'
    puts '    Suffix for newly created fullsize images. Default: "".'
    puts '--tn-size SIZE'
    puts '    Size for newly created thumbnail images. Default: "0".'
    puts '--tn-qual INT'
    puts '    Quality for newly created thumbnail images. Default: "40".'
    puts '--tn-prefix STRING'
    puts '    Prefix for newly created thumbnail images. Default: "tn_".'
    puts '--tn-suffix STRING'
    puts '    Suffix for newly created thumbnail images. Default: "".'
    puts '--gal-file STRING'
    puts '    Filename for the HTML file. Default: "index.html".'
    puts '--gal-title STRING'
    puts '    Title for the HTML gallery. Default: "HTML Thumbnail Gallery".'
    puts '--gal-desc STRING'
    puts '    Description for the gallery. Will be enclosed by p tags. ' \
        'Default: "".'
    puts '--gal-pprow INT'
    puts '    Pictures per row in the HTML gallery. Default: "5".'
    puts '--gal-gzip INT'
    puts '    Defines if the gallery file should be compressed. Default: "0".'
    puts '--col-bg HEXCOL'
    puts '    Specifies the background color. Default: "#cccccc".'
    puts '--col-text HEXCOL'
    puts '    Specifies the text color. Default: "#000000".'
    puts '--col-link HEXCOL'
    puts '    Specifies the color of unvisited links. Default: "#0000ff".'
    puts '--col-alink HEXCOL'
    puts '    Specifies the color of active links. Default: "#ff0000".'
    puts '--col-vlink HEXCOL'
    puts '    Specifies the color of visited links. Default: "#990099".'
    puts '--comment STRING'
    puts '    Adds the given string to the comment field in the image.'
    puts '--interlace | --interlaced | --progressive'
    puts '    Creates interlaced images.'
    puts '--use-exif'
    puts '    Fetches EXIF datetime information and displays it in the ' \
        'gallery.'
    puts '--use-names'
    puts '    Use original names for newly created images instead of ' \
        'numbering.'
    puts '--no-convert'
    puts '    Disables conversion of original images.'
    puts '--conv-opts STRING'
    puts '    Additional options for convert.'
    puts '--conv-opts-fs STRING'
    puts '    Additional options for convert (fullsize images only).'
    puts '--conv-opts-tn STRING'
    puts '    Additional options for convert (thumbnail images only).'
    puts '--quiet'
    puts '    Surpresses all messages going to STDOUT.'
    puts
    puts 'Please note that picconv will overwrite files in --out-dir.'
end

#==========================================================================
# Class definition for a single image.
#==========================================================================

class ImageHandle
    @@interlace   = false
    @@use_exif    = false
    @@comment     = 'created with picconv'
    @@c_opts      = ''
    @@c_opts_fs   = ''
    @@c_opts_tn   = ''
    @@im_size     = '640x640'
    @@im_qual     = '80'
    @@im_prefix   = ''
    @@im_suffix   = ''
    @@tn_size     = '0'
    @@tn_qual     = '40'
    @@tn_prefix   = 'tn_'
    @@tn_suffix   = ''
    @@exif_regexp = nil

    def initialize(filename, mimetype = nil)
        if File.exist?(filename)  and  File.file?(filename)
            @orig_filename = filename
            @im_filename   = nil
            @tn_filename   = nil
            @mimetype      = mimetype
            if @@use_exif
                self.fetch_exif_datetime()
            end
        else
            STDERR.puts "#{filename} is not a file!"
        end
    end

    def ImageHandle.general_options(interlace = false, use_exif = false,
                                    comment = 'created with picconv')
        @@interlace = interlace
        @@use_exif  = use_exif
        @@comment   = comment
    end

    def ImageHandle.conv_options(general = '', fs = '', tn = '')
        @@c_opts    = ''
        @@c_opts_fs = ''
        @@c_opts_tn = ''
    end

    def ImageHandle.im_options(size = '640x640', qual = '80', prefix = '',
                               suffix = '')
        @@im_size   = size
        @@im_qual   = qual
        @@im_prefix = prefix
        @@im_suffix = suffix
    end

    def ImageHandle.tn_options(size = '0', qual = '40', prefix = 'tn_',
                               suffix = '')
        @@tn_size   = size
        @@tn_qual   = qual
        @@tn_prefix = prefix
        @@tn_suffix = suffix
    end

    def fetch_exif_datetime()
        if @@use_exif
            if nil == @@exif_regexp
                @@exif_regexp = Regexp.new('.+\|(.+)')
            end
            data  = `exif -i "#{@orig_filename}"|grep '^0x9003|'`
            match = @@exif_regexp.match(data)
            if nil != match  and  2 == match.size()
                @exif_datetime = match[1]
                @exif_datetime.squeeze!(' ')
                @exif_datetime.chop!
            else
                @exif_datetime = nil
            end
        end
    end

    def im_convert!(out_dir, namebase, ext = nil)
        fullpath = "#{out_dir}/#{@@im_prefix}#{namebase}#{@@im_suffix}"
        if (nil != ext)
            fullpath += ".#{ext}"
        end
        fullpath.squeeze!('/')
        @im_filename = fullpath
        args  = "-thumbnail #{@@im_size} -quality #{@@im_qual}"
        args += " #{@@c_opts} #{@@c_opts_fs}"
        if @@interlace
            args += " -interlace Line"
        end
        cmd  = "convert #{args} -comment \"#{@@comment}\" "
        cmd += "\"#{@orig_filename}\" \"#{fullpath}\""
        `#{cmd}`
    end

    def tn_convert!(out_dir, namebase, ext = nil)
        if '0' != @@tn_size
            fullpath = "#{out_dir}/#{@@tn_prefix}#{namebase}#{@@tn_suffix}"
            if (nil != ext)
                fullpath += ".#{ext}"
            end
            fullpath.squeeze!('/')
            @tn_filename = fullpath
            args  = "-thumbnail #{@@tn_size} -quality #{@@tn_qual}"
            args += " #{@@c_opts} #{@@c_opts_tn}"
            if @@interlace
                args += " -interlace Line"
            end
            if nil != @im_filename
                basefile = @im_filename
            else
                basefile = @orig_filename
            end
            cmd  = "convert #{args} -comment \"#{@@comment}\" "
            cmd += "\"#{basefile}\" \"#{fullpath}\""
            `#{cmd}`
        end
    end

    #======================================================================
    # only get and set methods, attr_reader and attr_writer from here on
    #======================================================================

    def called_options?()
        @@called_options
    end

    def interlace?()
        @@interlace
    end

    def use_exif?()
        @@use_exif
    end

    def comment?()
        @@comment
    end

    def c_opts?()
        @@c_opts
    end

    def c_opts_fs?()
        @@c_opts_fs
    end

    def c_opts_tn?()
        @@c_opts_tn
    end

    def im_size?()
        @@im_size
    end

    def im_qual?()
        @@im_qual
    end

    def im_prefix?()
        @@im_prefix
    end

    def im_suffix?()
        @@im_suffix
    end

    def tn_size?()
        @@tn_size
    end

    def tn_qual?()
        @@tn_qual
    end

    def tn_prefix?()
        @@tn_prefix
    end

    def tn_suffix?()
        @@tn_suffix
    end

    attr_reader :orig_filename, :im_filename, :tn_filename
    attr_reader :mimetype, :exif_datetime
end

#==========================================================================
# Step I: Get and parse command line arguments.
#==========================================================================

# are there any arguments
if ARGV.length < 1
    header()
    puts "Type '#{$0} --help' for usage."
    exit 1
end

# just too lazy to write all those characters again and again
no_arg  = GetoptLong::NO_ARGUMENT
has_arg = GetoptLong::REQUIRED_ARGUMENT
opt_arg = GetoptLong::OPTIONAL_ARGUMENT

# parse arguments
options = GetoptLong.new(
    [ '--help', no_arg ],
    [ '--quiet', no_arg ],
    [ '--in-dir', has_arg ],
    [ '--out-dir', has_arg ],
    [ '--im-size', has_arg ],
    [ '--im-qual', has_arg ],
    [ '--im-prefix', has_arg ],
    [ '--im-suffix', has_arg ],
    [ '--tn-size', has_arg ],
    [ '--tn-qual', has_arg ],
    [ '--tn-prefix', has_arg ],
    [ '--tn-suffix', has_arg ],
    [ '--gal-file', has_arg ],
    [ '--gal-title', has_arg ],
    [ '--gal-desc', has_arg ],
    [ '--gal-pprow', has_arg ],
    [ '--gal-gzip', has_arg ],
    [ '--col-bg', has_arg ],
    [ '--col-text', has_arg ],
    [ '--col-link', has_arg ],
    [ '--col-alink', has_arg ],
    [ '--col-vlink', has_arg ],
    [ '--interlace', no_arg ],
    [ '--interlaced', no_arg ],
    [ '--progressive', no_arg ],
    [ '--use-exif', no_arg ],
    [ '--no-convert', no_arg ],
    [ '--use-names', no_arg ],
    [ '--comment', has_arg ],
    [ '--conv-opts', has_arg ],
    [ '--conv-opts-fs', has_arg ],
    [ '--conv-opts-tn', has_arg ]
)

# undo laziness
no_arg = has_arg = opt_arg = nil

# set defaults for all possible parameters
quiet     = false
in_dir    = nil
out_dir   = nil
im_size   = '640x640'
im_qual   = 80
im_prefix = ''
im_suffix = ''
tn_size   = '0'
tn_qual   = 40
tn_prefix = 'tn_'
tn_suffix = ''
gal_file  = 'index.html'
gal_title = 'HTML Thumbnail Gallery'
gal_desc  = ''
gal_pprow = 5
gal_gzip  = 0
col_bg    = '#cccccc'
col_text  = '#000000'
col_link  = '#0000ff'
col_alink = '#ff0000'
col_vlink = '#990099'
interlace = false
use_exif  = false
no_conv   = false
use_names = false
comment   = 'created with picconv'
c_opts    = ''
c_opts_fs = ''
c_opts_tn = ''

# overwrite defaults
options.each do |opt, arg|
    case opt
        when '--help'
            header(false)
            usage()
            exit 1
        when '--quiet'
            quiet = true
        when '--in-dir'
            in_dir = arg
        when '--out-dir'
            out_dir = arg
        when '--im-size'
            im_size = arg
        when '--im-qual'
            im_qual = arg.to_i
        when '--im-prefix'
            im_prefix = arg
        when '--im-suffix'
            im_suffix = arg
        when '--tn-size'
            tn_size = arg
        when '--tn-qual'
            tn_qual = arg.to_i
        when '--tn-prefix'
            tn_prefix = arg
        when '--tn-suffix'
            tn_suffix = arg
        when '--gal-file'
            gal_file = arg
        when '--gal-title'
            gal_title = arg
        when '--gal-desc'
            gal_desc = arg
        when '--gal-pprow'
            gal_pprow = arg.to_i
        when '--gal-gzip'
            gal_gzip = arg.to_i
        when '--col-bg'
            col_bg = arg
        when '--col-text'
            col_text = arg
        when '--col-alink'
            col_alink = arg
        when '--col-vlink'
            col_vlink = arg
        when '--interlace'
            interlace = true
        when '--interlaced'
            interlace = true
        when '--progressive'
            interlace = true
        when '--use-exif'
            use_exif = true
        when '--no-conv'
            no_conv = true
        when '--use-names'
            use_names = true
        when '--comment'
            comment += " # #{arg}"
        when '--conv-opts'
            c_opts += arg
        when '--conv-opts-fs'
            c_opts_fs += arg
        when '--conv-opts-tn'
            c_opts_tn += arg
    end
end

# show the startup message
header(quiet)

#==========================================================================
# Step II: Do some checks on those parameters.
#==========================================================================

# in-dir usable?
if nil == in_dir
    $stderr.puts 'Error: No in-dir supplied.'
    exit 10
elsif not FileTest.directory?(in_dir)
    $stderr.puts 'Error: The supplied in-dir is not a directory.'
    exit 11
elsif not FileTest.readable?(in_dir)
    $stderr.puts 'Error: The supplied in-dir is not readable.'
    exit 12
end

# out-dir usable?
if nil == out_dir
    $stderr.puts 'Error: No out-dir supplied.'
    exit 15
elsif not FileTest.directory?(out_dir)
    $stderr.puts 'Error: The supplied out-dir is not a directory.'
    exit 16
elsif not FileTest.writable?(out_dir)
    $stderr.puts 'Error: The supplied out-dir is not writable.'
    exit 17
end

# im-qual in range?
if im_qual < 1
    im_qual = 1
    $stderr.puts 'Warning: im-qual adjusted to 1.'
elsif im_qual > 100
    im_qual = 100
    $stderr.puts 'Warning: im-qual adjusted to 100.'
end

# tn-qual in range?
if tn_qual < 1
    tn_qual = 1
    $stderr.puts 'Warning: tn-qual adjusted to 1.'
elsif tn_qual > 100
    tn_qual = 100
    $stderr.puts 'Warning: tn-qual adjusted to 100.'
end

# non-equal pre-/suffixes?
if im_prefix == tn_prefix and im_suffix == tn_suffix
    $stderr.puts 'Error: {im,tn}-prefix and {im,tn}-suffix are equal.'
    exit 20
end

# gal-pprow greater than zero?
if gal_pprow < 1
    gal_pprow = 1
    $stderr.puts 'Warning: gal-pprow adjusted to 1.'
end

# gal-gzip valid?
if gal_gzip < 0
    gal_gzip = 0
    $stderr.puts 'Warning: gal-gzip adjusted to 0.'
elsif gal_gzip > 2
    gal_gzip = 2
    $stderr.puts 'Warning: gal-gzip adjusted to 2.'
end

#==========================================================================
# Step III: Get the names of the images in in-dir.
#==========================================================================

ImageHandle.general_options(interlace, use_exif, comment)
ImageHandle.conv_options(c_opts, c_opts_fs, c_opts_tn)
ImageHandle.im_options(im_size, im_qual, im_prefix, im_suffix)
ImageHandle.tn_options(tn_size, tn_qual, tn_prefix, tn_suffix)

images = Array.new

puts 'Searching for image files...' unless quiet
Dir.foreach(in_dir) do | entry |
    fullpath = "#{in_dir}/#{entry}".squeeze('/')
    if FileTest.file?(fullpath)
        mimetype = `file -bi "#{fullpath}"`
        if 0 == mimetype.index('image')
            orig = ImageHandle.new(fullpath, mimetype)
            images.push(orig)
        end
    end
end
puts "...done. Found #{images.length} images." unless quiet
puts unless quiet

images.sort! { |x, y|  x.orig_filename <=> y.orig_filename }

#==========================================================================
# Step IV: Convert found images.
#==========================================================================

num_conv  = 0
converted = 0

unless no_conv
    puts 'Converting images...' unless quiet
    images.each do | img |
        print "    #{File.basename(img.orig_filename)}" unless quiet
        $stdout.flush unless quiet
        # get the basename and extension of the file
        filename = File.basename(img.orig_filename)
        ext      = filename.rindex('.')
        if nil != ext
            basename = filename.slice(0, ext)
            ext      = filename.slice(ext + 1, img.orig_filename.length - ext)
        else
            basename = filename
            ext      = nil
        end
        # get the new filename
        num_conv += 1
        if not use_names
            newname = num_conv.to_s
            while newname.length < 5
                newname = "0" + newname
            end
        else
            newname = basename
        end
        # create fullsize image
        img.im_convert!(out_dir, newname, ext)
        print " -> #{File.basename(img.im_filename)}" unless quiet
        $stdout.flush unless quiet
        # create thumbnail image
        if '0' != img.tn_size?
            img.tn_convert!(out_dir, newname, ext)
            print " -> #{File.basename(img.tn_filename)}" unless quiet
            $stdout.flush unless quiet
        end
        puts unless quiet
        converted += 1
    end
    puts "...done. Converted #{converted} images." unless quiet
    puts unless quiet
end

#==========================================================================
# Step V: Create HTML file.
#==========================================================================

filename  = "#{out_dir}/#{gal_file}".squeeze('/')

puts 'Creating HTML file...' unless quiet
fh = File.new(filename, 'w')
fh.puts '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" ' \
    '"http://www.w3.org/TR/html4/looses.dtd">'
fh.puts '<html>'
fh.puts '<head>'
fh.puts '<meta http-equiv="Content-Type" content="text/html; ' \
    'charset=ISO-8859-1">'
fh.puts "<title>#{gal_title}</title>"
fh.puts "<meta name=\"generator\" content=\"picconv #{PICCONV_VERSION}, " \
    "#{PICCONV_URL}\">"
fh.puts '<meta name="robots" content="noindex,noarchive,follow">'
fh.puts '<style type="text/css">'
fh.puts 'h1 { font-size: x-large; }'
fh.puts 'td { font-size: small; text-align: center; vertical-align: middle; }'
fh.puts '</style>'
fh.puts '</head>'
fh.puts "<body bgcolor=\"#{col_bg}\" text=\"#{col_text}\" " \
    "link=\"#{col_link}\" alink=\"#{col_alink}\" vlink=\"#{col_vlink}\">"
fh.puts "<h1 align=\"center\">#{gal_title}</h1>"
if '' != gal_desc
    fh.puts "<p align=\"center\">#{gal_desc}</p>"
end
fh.puts '<table align="center" border="1" cellspacing="1" cellpadding="4" ' \
    'summary="Thumbnail gallery">'
pprow = 0
images.each do | img |
    fsname = File.basename(img.im_filename)
    if nil != img.tn_filename
        tnname = File.basename(img.tn_filename)
    else
        tnname = fsname
    end
    if 0 == pprow
        fh.puts "<tr>"
    end
    if nil != img.exif_datetime
        exifinfo = '<br />' + img.exif_datetime
    else
        exifinfo = ''
    end
    fh.puts "<td><a href=\"#{fsname}\"><img src=\"#{tnname}\" alt=\"preview " \
        "for #{fsname}\"></a>#{exifinfo}</td>"
    pprow += 1
    if pprow >= gal_pprow
        fh.puts "</tr>"
        pprow = 0
    end
end
if 0 != pprow
    while pprow < gal_pprow
        fh.puts "<td>&nbsp;</td>"
        pprow += 1
    end
    fh.puts "</tr>"
end
fh.puts "</table>"
fh.puts '<p align="center" style="font-size: x-small;">Gallery created with ' \
    "<a href=\"#{PICCONV_URL}\">picconv</a>.</p>"
fh.puts "</body>"
fh.puts "</html>"
fh.close()
if 0 < gal_gzip
    `gzip -9 #{filename}`
    if 2 == gal_gzip
        `gzip -dc #{filename}.gz > #{filename}`
    end
end
puts '...done.' unless quiet
puts unless quiet

#==========================================================================
# Step VI: Finish with style.
#==========================================================================

puts 'Thank you for using picconv.' unless quiet
exit 0

