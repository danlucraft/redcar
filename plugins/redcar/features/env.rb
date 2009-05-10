
$:.push(File.expand_path(File.dirname(__FILE__) + "/../../../vendor/gutkumber/lib"))
require 'gutkumber'

Gutkumber.start_application_thread do
  module Redcar
    module App
      class << self
        attr_accessor :ARGV
      end
      self.ARGV = []
    end
  end

  begin
    load File.dirname(__FILE__) + "/../../../bin/redcar"
  rescue Object => e
    puts "error loading Redcar"
    puts e.message
    puts e.backtrace
  end
end

loop do
  sleep 0.1
  break if Gutkumber.ready_to_test?
end

Dir[File.dirname(__FILE__) + "/../../*/features/lib/*.rb"].each {|fn| require fn}
Dir[File.dirname(__FILE__) + "/../../*/features/step_definitions/*_steps.rb"].each {|fn| require fn}

Redcar::Preference.return_defaults = true

World(FreeBASE::DataBusHelper)
World(FeaturesHelper)

After do
  Gtk.queue do
    while dialog = Gtk::Dialog._cucumber_running_dialogs.pop
      dialog.close
    end
    Redcar.win.tabs.each(&:close)
    Redcar::UnifyAll.new.do
    Redcar::CommandHistory.clear
    make_event_key("Escape", :press).put
    make_event_key("Escape", :release).put
  end
end

at_exit do
  Gtk.queue do
    Redcar::App.quit
  end
end



