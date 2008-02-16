
puts "(startup.rb)"

puts "performance test"
require 'ruby-prof'

def stop
  Thread.new {
    sleep 1
    Redcar::App.quit
  }
end

if Redcar::App.ARGV.include? "--test-perf-load"
  new_tab = Redcar.new_tab
  new_tab.filename = "/home/dan/projects/redcar/freebase2/lib/freebase/readers.rb"  
  RubyProf.start
  new_tab.load  
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, 0)
  stop
elsif Redcar::App.ARGV.include? "--test-perf-edit"
  tab = Redcar.new_tab
  tab.filename = "/home/dan/projects/redcar/freebase2/lib/freebase/readers.rb"  
  tab.load
  tab.focus
  RubyProf.start
  tab.cursor = tab.iter(TextLoc(65, 39))
  3.times do
    5.times do 
      tab.buffer.signal_emit("delete_range", 
                             tab.iter(tab.cursor_iter.offset-1),
                             tab.cursor_iter)
      sleep 1
    end
    5.times do 
      tab.buffer.signal_emit("insert_text",
                             tab.cursor_iter,
                             "A",
                             1)
      sleep 1
    end
  end
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, 0)
  stop
elsif Redcar::App.ARGV.include? "--test-syntax"
  $BUS['/plugins/syntaxview/actions/test'].call
  stop
end
