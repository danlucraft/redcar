
require File.dirname(__FILE__) + "/formatters/gtk_formatter.rb"
require File.dirname(__FILE__) + "/formatters/gtk_progress_formatter.rb"

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
        class << self
          attr_accessor :in_cucumber_process
          attr_accessor :ready_for_cucumber
        end
        self.in_cucumber_process = true
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
  break if Redcar::Testing::InternalCucumberRunner.ready_for_cucumber
end

Dir[File.dirname(__FILE__) + "/../../*/features/lib/*.rb"].each {|fn| require fn}
Dir[File.dirname(__FILE__) + "/../../*/features/step_definitions/*_steps.rb"].each {|fn| require fn}

Redcar::Preference.return_defaults = true

World do |world|
  world.extend(FreeBASE::DataBusHelper)
  world.extend(FeaturesHelper)
  world
end

After do
  Redcar.win.tabs.each(&:close)
  Redcar::UnifyAll.new.do
  Redcar::CommandHistory.clear
  make_event_key("Escape", :press).put
  make_event_key("Escape", :release).put
  Gtk.main_iteration while Gtk.events_pending?
end  



