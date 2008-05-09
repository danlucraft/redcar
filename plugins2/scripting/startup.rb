
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

def do_edit
  doc.insert(doc.iter(TextLoc(230, 0)), "        when ")
  
  2.times do
    1.times do 
      doc.signal_emit("insert_text",
                      doc.iter(TextLoc(230, 13)),
                      "'",
                      1)
    end
    1.times do 
      doc.signal_emit("delete_range", 
                      doc.iter(TextLoc(230, 13)),
                      doc.iter(TextLoc(230, 14)))
    end
  end
end

if Redcar::App.ARGV.include? "--test-perf-load"
  require 'ruby-prof'
  RubyProf.start
  Coms::OpenTab.new("/home/dan/projects/redcar/rak").do
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, :min_percent => 1)
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-time-load"
  st = Time.now
  Coms::OpenTab.new("/home/dan/projects/redcar/rak").do
  et = Time.now
  puts "time to load: #{et-st}"
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-perf-edit"
  require 'ruby-prof'
  Coms::OpenTab.new("/home/dan/projects/rak/bin/rak").do
  RubyProf.start
  do_edit
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, :min_percent => 1)
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-time-edit"
  Coms::OpenTab.new("/home/dan/projects/rak/bin/rak").do
  st = Time.now
  do_edit
  et = Time.now
  puts "time to edit #{et-st}"
  stop_redcar
elsif Redcar::App.ARGV.include? "--test"
  ix = Redcar::App.ARGV.index "--test"
  plugin = Redcar::App.ARGV[ix+1]
  test_plugin plugin
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-all"
  bus("system/test").call
#   bus["/plugins"].children.each do |plugin|
#     test_plugin plugin.name
#   end
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
