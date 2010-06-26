#!/usr/bin/env ruby
require 'rbconfig'
require 'find'
require 'ftools'
require 'tempfile'
include Config

LIBDIR      = "lib"
LIBDIR_MODE = 0644

BINDIR      = "bin"
BINDIR_MODE = 0755


$srcdir            = CONFIG["srcdir"]
$version           = CONFIG["MAJOR"]+"."+CONFIG["MINOR"]
$libdir            = File.join(CONFIG["libdir"], "ruby", $version)
$archdir           = File.join($libdir, CONFIG["arch"])
$site_libdir       = $:.find {|x| x =~ /site_ruby$/}
$bindir            = CONFIG["bindir"]
$ruby_install_name = CONFIG['ruby_install_name'] || CONFIG['RUBY_INSTALL_NAME']
$ruby              = File.join($bindir, $ruby_install_name || 'ruby')

if !$site_libdir
  $site_libdir = File.join($libdir, "site_ruby")
elsif $site_libdir !~ %r/#{Regexp.quote($version)}/
  $site_libdir = File.join($site_libdir, $version)
end

def install_rb(srcdir=nil, destdir=nil, mode=nil, bin=nil)
#{{{
  path   = []
  dir    = []
  Find.find(srcdir) do |f|
    next unless FileTest.file?(f)
    next if (f = f[srcdir.length+1..-1]) == nil
    next if (/CVS$/ =~ File.dirname(f))
    path.push f
    dir |= [File.dirname(f)]
  end
  for f in dir
    next if f == "."
    next if f == "CVS"
    File::makedirs(File.join(destdir, f))
  end
  for f in path
    next if (/\~$/ =~ f)
    next if (/^\./ =~ File.basename(f))
    unless bin
      File::install(File.join(srcdir, f), File.join(destdir, f), mode, true)
    else
      from = File.join(srcdir, f)
      to = File.join(destdir, f)
      shebangify(from) do |sf|
        $deferr.print from, " -> ", File::catname(from, to), "\n"
        $deferr.printf "chmod %04o %s\n", mode, to 
        File::install(sf, to, mode, false)
      end
    end
  end
#}}}
end
def shebangify f
#{{{
  open(f) do |fd|
    buf = fd.read 42 
    if buf =~ %r/^\s*#\s*!.*ruby/o
      ftmp = Tempfile::new("#{ $$ }_#{ File::basename(f) }")
      begin
        fd.rewind
        ftmp.puts "#!#{ $ruby  }"
        while((buf = fd.read(8192)))
          ftmp.write buf
        end
        ftmp.close
        yield ftmp.path
      ensure
        ftmp.close!
      end
    else
      yield f
    end
  end
#}}}
end
def ARGV.switch
#{{{
  return nil if self.empty?
  arg = self.shift
  return nil if arg == '--'
  if arg =~ /^-(.)(.*)/
    return arg if $1 == '-'
    raise 'unknown switch "-"' if $2.index('-')
    self.unshift "-#{$2}" if $2.size > 0
    "-#{$1}"
  else
    self.unshift arg
    nil
  end
#}}}
end
def ARGV.req_arg
#{{{
  self.shift || raise('missing argument')
#}}}
end


#
# main program
#

libdir = $site_libdir
bindir = $bindir

begin
  while switch = ARGV.switch
    case switch
    when '-d', '--destdir'
      libdir = ARGV.req_arg
    when '-l', '--libdir'
      libdir = ARGV.req_arg
    when '-b', '--bindir'
      bindir = ARGV.req_arg
    when '-r', '--ruby'
      $ruby = ARGV.req_arg
    else
      raise "unknown switch #{switch.dump}"
    end
  end
rescue
  STDERR.puts $!.to_s
  STDERR.puts File.basename($0) + 
    " -d <destdir>" +
    " -l <libdir>" +
    " -b <bindir>"
    " -r <ruby>"
  exit 1
end    

install_rb(LIBDIR, libdir, LIBDIR_MODE)
install_rb(BINDIR, bindir, BINDIR_MODE, bin=true)

