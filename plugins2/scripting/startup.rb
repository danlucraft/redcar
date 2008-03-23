
puts "(scripting/startup.rb)"

require 'ruby-prof'

def stop_redcar
  Thread.new {
    Redcar::App.quit
  }
end

def test_plugin(plugin_name)
  if plugin_name and bus("/plugins/").has_child?(plugin_name)
    if bus("/plugins/#{plugin_name}/actions/").has_child? "test"
      puts "="*75
      puts "Testing: " + plugin_name
      puts "-"*75
      bus["/plugins/#{plugin_name}/actions/test"].call
      puts "="*75
    else
      puts "--test: plugin #{plugin_name} has no tests."
    end
  else
    puts "--test: No such plugin (#{plugin_name})."
  end
end

if Redcar::App.ARGV.include? "--test-perf-load"
  new_tab = Redcar.new_tab
  new_tab.filename = "/home/dan/projects/redcar/freebase2/lib/freebase/readers.rb"  
  RubyProf.start
  new_tab.load  
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
  stop_redcar
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
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-syntax"
  bus['/plugins/syntaxview/actions/test'].call
  stop_redcar
elsif Redcar::App.ARGV.include? "--test"
  ix = Redcar::App.ARGV.index "--test"
  plugin = Redcar::App.ARGV[ix+1]
  test_plugin plugin
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-all"
  bus["/plugins"].children.each do |plugin|
    test_plugin plugin.name
  end
  stop_redcar
elsif Redcar::App.ARGV.include? "--demo"
  win.panes.first.split_horizontal
  win.panes.last.new_tab(Tab, Gtk::Button.new("foo"))
  win.panes.last.new_tab(Tab, Gtk::Button.new("bar"))
  win.panes.last.new_tab(Tab, Gtk::Button.new("baz"))
elsif Redcar::App.ARGV.include? "--current"
  win.new_tab(EditTab)
  stop_redcar
end
