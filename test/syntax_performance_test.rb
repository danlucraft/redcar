
require 'lib/redcar'
require 'benchmark'

include Redcar

$small_ruby_file = IO.readlines("test/fixtures/user_commands.rb").join
$medium_plist_file = IO.readlines("test/fixtures/ruby.plist").join

$html_gr = Syntax::Grammar.new(eval(IO.readlines("test/fixtures/html_grammar.plist").join)[0])
$large_html_file = IO.readlines("test/fixtures/medium.html").join

Syntax.load_grammars
$ruby_gr = Syntax.grammar(:name => "Ruby")
$html_gr = Syntax.grammar(:name => "HTML")

def small(n)
  n.times do
    sc = Syntax::Scope.new(:pattern => $ruby_gr,
                           :grammar => $ruby_gr,
                           :start => TextLoc.new(0, 0))
    pr = Syntax::Parser.new(sc, [$ruby_gr], "")
    pr.add_lines($small_ruby_file, :lazy => false)
  end
end

def medium(n)
#   n.times do
#     sc = Syntax::Scope.new(:pattern => $ruby_gr,
#                                     :grammar => $ruby_gr,
#                                     :start => TextLoc.new(0, 0))
#     pr = Syntax::Parser.new(sc, [$ruby_gr], "")
#     pr.add_lines($medium_plist_file, :lazy => false)
#   end
end
  
def large(n)
  n.times do
    sc = Syntax::Scope.new(:pattern => $html_gr,
                           :grammar => $html_gr,
                           :start => TextLoc.new(0, 0))
    pr = Syntax::Parser.new(sc, [$html_gr], "")
    pr.add_lines($large_html_file, :lazy => false)
  end
end

Benchmark.bmbm(15) do |x|
  x.report("user_commands") do
    small(50)
  end
  x.report("medium.html") do
    large(15)
  end
end
puts
Instruments.report :possible_patterns_Ruby
Instruments.report :possible_patterns_checked_Ruby
Instruments.report :possible_patterns_HTML
Instruments.report :possible_patterns_checked_HTML


# require 'ruby-prof'
# RubyProf.start

# small(50)
# large(10)

# result = RubyProf.stop
# printer = RubyProf::GraphHtmlPrinter.new(result)
# printer.print(STDOUT, 0)
