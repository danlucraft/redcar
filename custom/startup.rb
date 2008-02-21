
puts "(startup.rb)"

puts "performance test"
require 'ruby-prof'

def stop
  Thread.new {
    sleep 1
    Redcar.quit
  }
end

if Redcar::App.ARGV.include? "--test-perf-load-file"
  RubyProf.start
  8.times do
    new_tab = Redcar.new_tab
    new_tab.filename = "/homes/dbl/projects/redcar/freebase2/lib/freebase/readers.rb"  
    new_tab.load  
    new_tab.close(true)
  end
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
  stop
elsif Redcar::App.ARGV.include? "--test-perf-edit"
  tab = Redcar.new_tab
  tab.filename = "/homes/dbl/projects/redcar/freebase2/lib/freebase/readers.rb"  
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
  printer.print(STDOUT)
  stop
elsif Redcar::App.ARGV.include? "--test-perf-long-line"
  new_tab = Redcar.new_tab
  new_tab.replace "\"asdf\"*3 + "*10
  RubyProf.start
  
  new_tab.cursor = new_tab.iter(TextLoc(0, 100))
  
  3.times do
    5.times do 
      new_tab.buffer.signal_emit("insert_text",
                             new_tab.cursor_iter,
                             "1",
                             1)
      sleep 1
    end
    5.times do 
      new_tab.buffer.signal_emit("delete_range", 
                             new_tab.iter(new_tab.cursor_iter.offset-1),
                             new_tab.cursor_iter)
      sleep 1
    end
  end
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
  stop
elsif Redcar::App.ARGV.include? "--test-syntax"
  $BUS['/plugins/syntaxview/actions/test'].call
  stop
end
