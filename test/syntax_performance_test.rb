
require 'vendor/keyword_processor'
require 'lib/plist'
require 'lib/syntax'
require 'lib/theme'
require 'lib/colourer'
require 'benchmark'

grammar = {
  "name" => "My Language",
  "comment" => "Example grammar 1",
  "scopeName" => 'source.untitled',
  "fileTypes" => [ ".rb", ".rjs" ],
  "firstLineMatch" => "#! /usr/bin/ruby",
  "foldingStartMarker" => '\{\s*$',
  "foldingStopMarker" => '^\s*\}',
  "patterns" => [
                 {  "name" => 'keyword.control.untitled',
                   "match" => '\b(def|else|class|if|while|for|return|do|end)\b'
                 },
                 {  "name" => 'comment.line',
                   "match" => '^\\s*#.*$'
                 },
                 {
                   "name" => 'constant',
                   "match"=> '\\b[A-Z]\\w+\\b'
                 },
                 {  "name" => 'string.quoted.double.untitled',
                   "begin" => '"',
                   "end" => '"',
                   "patterns" => [
                                  {  
                                    "name" => 'constant.character.escape.untitled',
                                    "match" => '\\\\.',
                                  }
                                 ]
                 }
                ]
}
$gr = Redcar::Syntax::Grammar.new(grammar)

xml = IO.readlines(File.dirname(__FILE__)+"/../textmate/Themes/MacClassic.tmTheme").join
plist = Redcar::Plist.plist_from_xml(xml)
th = Redcar::Theme.new(plist[0])

$small_ruby_file = IO.readlines("test/fixtures/user_commands.rb").join
$medium_plist_file = IO.readlines("test/fixtures/ruby.plist").join

$html_gr = Redcar::Syntax::Grammar.new(eval(IO.readlines("test/fixtures/html_grammar.plist").join)[0])
$large_html_file = IO.readlines("test/fixtures/html.html").join

def small(n)
  n.times do
    sc = Redcar::Syntax::Scope.new(:pattern => $gr,
                                    :grammar => $gr,
                                    :start => Redcar::Syntax::TextLoc.new(0, 0))
    pr = Redcar::Syntax::Parser.new(sc, [$gr], "")
    pr.add_lines($small_ruby_file)
  end
end

def medium(n)
  n.times do
    sc = Redcar::Syntax::Scope.new(:pattern => $gr,
                                    :grammar => $gr,
                                    :start => Redcar::Syntax::TextLoc.new(0, 0))
    pr = Redcar::Syntax::Parser.new(sc, [$gr], "")
    pr.add_lines($medium_plist_file)
  end
end
  
def large(n)
  n.times do
    sc = Redcar::Syntax::Scope.new(:pattern => $html_gr,
                                    :grammar => $html_gr,
                                    :start => Redcar::Syntax::TextLoc.new(0, 0))
    pr = Redcar::Syntax::Parser.new(sc, [$html_gr], "")
    pr.add_lines($large_html_file)
  end
end

Benchmark.bmbm(15) do |x|
  x.report("user_commands") do
    small(2)
  end
  x.report("ruby.plist") do
    medium(2)
  end
  x.report("graph.html") do
    large(2)
  end
end

# require 'ruby-prof'
# RubyProf.start

# small(2)
# medium(2)
# large(2)

# result = RubyProf.stop
# printer = RubyProf::GraphHtmlPrinter.new(result)
# printer.print(STDOUT, 0)
