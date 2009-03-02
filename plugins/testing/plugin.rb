

module Redcar
  class TestingPlugin < Redcar::Plugin
    on_load do
      Gtk.idle_add do
        Redcar::Testing.run_features
        false
      end
    end
  end
end

load File.dirname(__FILE__) + "/lib/testing.rb"
load File.dirname(__FILE__) + "/lib/runners/rspec/formatters.rb"
load File.dirname(__FILE__) + "/lib/runners/internal_rspec_runner.rb"
load File.dirname(__FILE__) + "/lib/runners/internal_cucumber_runner.rb"
load File.dirname(__FILE__) + "/tabs/test_view_tab.rb"

