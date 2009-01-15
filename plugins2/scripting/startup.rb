
def stop_redcar
  puts "stopping redcar..."
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
  doc = Redcar.tab.document
  
  10.times do
    "+:name.to_s".scan(/./).each_with_index do |l, i|
      doc.signal_emit("insert_text",
                      doc.iter(TextLoc(1913, 31+i)),
                      l, 1)
#       p doc.get_line(1913)
#       sleep 0.5
    end
    11.times do |i|
      doc.signal_emit("delete_range", 
                      doc.iter(TextLoc(1913, 31+11-i-1)),
                      doc.iter(TextLoc(1913, 31+11-i)))
#       p doc.get_line(1913)
#       sleep 0.5
    end
  end
end

if Redcar::App.ARGV.include? "--test-perf-load"
  require 'ruby-prof'
  RubyProf.start
  OpenTab.new("/home/dan/projects/redcar/rak2000").do
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, :min_percent => 1)
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-time-load"
#  Coms::OpenTab.new("/home/dan/projects/redcar/rak3000").do
  Redcar::OpenTab.new("/home/dan/projects/gtkmateview/samples/rak").do
  Redcar.win.tabs.each(&:close)
  puts "starting load...."
  st = Time.now
  Redcar::OpenTab.new("/home/dan/projects/gtkmateview/samples/rak").do
  et = Time.now
  puts "time to load: #{et-st}"
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-perf-edit"
  require 'ruby-prof'
  Coms::OpenTab.new("/home/dan/projects/redcar/rak2000").do
  RubyProf.start
  do_edit
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT, :min_percent => 1)
  stop_redcar
elsif Redcar::App.ARGV.include? "--test-time-edit"
  Coms::OpenTab.new("/home/dan/projects/rak/bin/rak2000").do
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
elsif ix = Redcar::App.ARGV.index("--spec")
  plugin = Redcar::App.ARGV[ix+1]
  Redcar::Hook.attach(:redcar_start) do
    begin
      if plugin
        Redcar::Testing::InternalRSpecRunner.spec_plugin(plugin)
      else
        bus("/plugins").children.each do |child|
          Redcar::Testing::InternalRSpecRunner.spec_plugin(child.name)
        end
      end
    rescue => e
      puts "error in Redcar::Testing.spec_plugin"
      puts e.message
      puts e.backtrace
    end
    stop_redcar
  end
elsif Redcar::App.ARGV.include?("--spec-all")
  Redcar::Hook.attach(:redcar_start) do
    begin
      Redcar::Testing::InternalRSpecRunner.spec_all_plugins
    end
    stop_redcar
  end
end



