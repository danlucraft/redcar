
require 'ruby-prof'

def stop_redcar
  Thread.new {
    Redcar::App.quit
  }
end

def test_plugin(plugin_name)
  plugin_name, testcase = plugin_name.split(":")
  if plugin_name and bus("/plugins/").has_child?(plugin_name)
    if bus("/plugins/#{plugin_name}/actions/").has_child? "test"
      puts "\nTesting: " + plugin_name
      puts "-"*75
      if testcase
        tcs = bus["/plugins/#{plugin_name}/actions/test"].children.map(&:name)
        tcs.select {|tc| tc =~ /#{testcase}/}.each do |tc|
          bus["/plugins/#{plugin_name}/actions/test/#{tc}"].call
        end
      else
        bus["/plugins/#{plugin_name}/actions/test"].call
      end
      puts "-"*75
    else
      puts "--test: plugin #{plugin_name} has no tests."
    end
  else
    puts "--test: No such plugin (#{plugin_name})."
  end
end

if Redcar::App.ARGV.include? "--test-perf-load"
  RubyProf.start
  Coms::OpenTab.new("/home/dan/projects/redcar/freebase2/lib/freebase/readers.rb").do
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-perf-edit"
  Coms::OpenTab.new("/homes/dbl/projects/redcar/freebase2/lib/freebase/readers.rb").do
  RubyProf.start
  doc.cursor = doc.char_count
  10.times do
    5.times do 
      doc.signal_emit("insert_text",
                      doc.cursor_iter,
                      "File.rm",
                      7)
    end
    5.times do 
      doc.signal_emit("delete_range", 
                      doc.iter(doc.char_count-7),
                      doc.iter(doc.char_count))
    end
  end
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
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
