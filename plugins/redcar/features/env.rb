
$:.push(File.expand_path(File.dirname(__FILE__) + "/../../../vendor/gutkumber/lib"))
require 'gutkumber'

# need to start Redcar in a new thread because FreeBASE blocks.
Thread.new do
  module Redcar
    module App
      class << self
        attr_accessor :ARGV
      end
      self.ARGV = []
    end

    module Testing
      class InternalCucumberRunner
        def self.begin_tests
          @ready_for_test = true
        end
        
        def self.ready_for_test?
          @ready_for_test
        end
      end
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
  break if Redcar::Testing::InternalCucumberRunner.ready_for_test?
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
    while dialog = Zerenity::Base.open_dialogs.pop
      dialog.destroy
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



