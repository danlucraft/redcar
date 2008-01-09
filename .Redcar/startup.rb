
puts "(startup.rb)"

puts "performance test"
require 'ruby-prof'

new_tab = Redcar.new_tab
new_tab.filename = "/home/dan/projects/redcar/freebase2/lib/freebase/readers.rb"  
RubyProf.start
new_tab.load  
result = RubyProf.stop
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 0)

# $BUS['/plugins/syntaxview/actions/test'].call

Thread.new {
  sleep 1
  Redcar.quit
}
