#!/usr/bin/env ruby -w

# if we are not called directly from TM (e.g. JavaScript) the caller
# should ensure that RUBYLIB is set properly
$: << "#{ENV["TM_SUPPORT_PATH"]}/lib" if ENV.has_key? "TM_SUPPORT_PATH"
require "escape"

require "erb"
include ERB::Util

term = ARGV.shift

def link_methods(prefix, methods)
  methods.split(/(,\s*)/).map do |match|
    match[0] == ?, ?
      match : "<a href=\"javascript:ri('#{prefix}#{match}')\">#{match}</a>"
  end.join
end

documentation = h(`ri -T #{e_sh term}`) rescue "<h1>ri Command Error.</h1>"

documentation.gsub!(/(\s|^)\+(\w+)\+(\s|$)/, "\\1<code>\\2</code>\\3")

if documentation.include? "More than one method matched"
  methods       = documentation.split(/\n[ \t]*\n/).last.strip.split(/,\s*/)
  list_items    = methods.inject("") do |str, item|
    str + "<li><a href=\"javascript:ri('#{item}')\">#{item}</a></li>\n"
  end
  documentation = "<h1>Multiple Matches:</h1>\n<ul>\n#{list_items}</ul>\n"
elsif documentation.sub!( /\A(-+\s+)([A-Z_]\w*)(#|::|\.)/,
                          "\\1<a href=\"javascript:ri('\\2')\">\\2</a>\\3" )
  # do nothing--added class/module link
else
  documentation.sub!( /\A(-+\s+Class: \w* < )([^\s<]+)/,
                            "\\1<a href=\"javascript:ri('\\2')\">\\2</a>" )
  documentation.sub!(/(Includes:\s+-+\s+)(.+?)([ \t]*\n[ \t]*\n|\s*\Z)/m) do
    head, meths, foot = $1, $2, $3
    head + meths.gsub(/([A-Z_]\w*)\(([^)]*)\)/) do |match|
      "<a href=\"javascript:ri('#{$1}')\">#{$1}</a>(" +
      link_methods("#{$1}#", $2) + ")"
    end + foot
  end
  documentation.sub!(/(Class methods:\s+-+\s+)(.+?)([ \t]*\n[ \t]*\n|\s*\Z)/m) do
    $1 + link_methods("#{term}::", $2) + $3
  end
  documentation.sub!(/(Instance methods:\s+-+\s+)(.+?)([ \t]*\n[ \t]*\n|\s*\Z)/m) do
    $1 + link_methods("#{term}#", $2) + $3
  end
end

puts documentation.gsub("\n", "<br />")