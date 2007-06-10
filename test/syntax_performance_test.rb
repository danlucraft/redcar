
require 'lib/redcar'
require 'benchmark'

include Redcar

$small_ruby_file = IO.readlines("test/fixtures/grammar.rb").join
$medium_plist_file = IO.readlines("test/fixtures/ruby.plist").join

$large_html_file = IO.readlines("test/fixtures/medium.html").join

rubylines = $small_ruby_file.split("\n")
htmllines = $large_html_file.split("\n")
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

if ARGV[0] == "benchmark"
  Benchmark.bmbm(15) do |x|
    x.report("Ruby 250x50 ") do
      small(50)
    end
    x.report("HTML 4500x1") do
      large(1)
    end
  end
  puts
  Instrument.report :add_child
  Instrument.report :add_child_at_end?
  Instrument.report :colourer_children_checked
  Instrument.report :colourer_children_on_line
  # Instrument.report :possible_patterns_Ruby
  # Instrument.report :matching_patterns_Ruby
  # Instrument.report :possible_patterns_checked_Ruby
  # Instrument.report :line_repeats_Ruby
  # # Instrument.report :duplicate_starts_Ruby
  # Instrument.report :possible_patterns_HTML
  # Instrument.report :matching_patterns_HTML
  # Instrument.report :possible_patterns_checked_HTML
  # Instrument.report :line_repeats_HTML
  # Instrument.report :duplicate_starts_HTML

  # ruby_hints = {}
  # $ruby_gr.pattern_lookup.each do |name, pattern|
  #   ruby_hints[name] = pattern.hint unless pattern.is_a? Array
  # end
  # html_hints = {}
  # $html_gr.pattern_lookup.each do |name, pattern|
  #   html_hints[name] = pattern.hint unless pattern.is_a? Array
  # end
  # ruby_hints.to_a.sort_by{|a| -a[1]}.each {|a| puts "#{a[0]}: #{a[1]}"}
  # html_hints.to_a.sort_by{|a| -a[1]}.each {|a| puts "#{a[0]}: #{a[1]}"}

  # Syntax.grammars.each {|_, gr| gr.clear_possible_patterns }
  # Syntax.cache_grammars
elsif ARGV[0] == "profile"
  require 'ruby-prof'
  RubyProf.start

  small(50)
  large(10)

  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, 0)
elsif ARGV[0] == "colour"
  Redcar.startup(:output => :silent)
  rtab = Redcar.new_tab
  rtab.focus
  rtab.set_grammar(Syntax.grammar(:name => 'Ruby'))
  htab = Redcar.new_tab
  htab.focus
  htab.set_grammar(Syntax.grammar(:name => 'HTML'))
  $REDCAR_ENV["test"] = true
  $REDCAR_ENV["nonlazy"] = true
  Benchmark.bmbm(15) do |x|
    x.report("Ruby") do
      10.times do
        rtab.replace($small_ruby_file)
      end
    end
    x.report("Ruby Replace") do
      1000.times do
        rtab.insert(TextLoc.new(lines.length/2, 0), "puts \"hello\" + :foo ")
        rtab.delete(TextLoc.new(lines.length/2, 0), TextLoc.new(lines.length/2, 20))
      end
    end
    x.report("HTML") do
      2.times do
        htab.replace($large_html_file)
      end
    end
  end
  Instrument.report :colourer_children_checked
  Instrument.report :colourer_children_on_line
elsif ARGV[0] == "colourprofile"
  Redcar.startup(:output => :silent)
  rtab = Redcar.new_tab
  rtab.focus
  rtab.set_grammar(Syntax.grammar(:name => 'Ruby'))
  htab = Redcar.new_tab
  htab.focus
  htab.set_grammar(Syntax.grammar(:name => 'HTML'))
  $REDCAR_ENV["test"] = true
  $REDCAR_ENV["nonlazy"] = true
  require 'ruby-prof'
  RubyProf.start

#   10.times do
#     rtab.replace($small_ruby_file)
#   end
  1000.times do
    rtab.insert(TextLoc.new(rubylines.length/2, 0), "puts \"hello\" + :foo ")
    rtab.delete(TextLoc.new(rubylines.length/2, 0), TextLoc.new(rubylines.length/2, 20))
  end
  1000.times do
    htab.insert(TextLoc.new(htmllines.length/2, 0), "<p>Hello</p>")
    htab.delete(TextLoc.new(htmllines.length/2, 0), TextLoc.new(htmllines.length/2, 20))
  end
#   2.times do
#     htab.replace($large_html_file)
#   end
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, 0)
  Instrument.report :priority
  
  Instrument.report :colourer_children_checked
  Instrument.report :colourer_children_on_line
end
