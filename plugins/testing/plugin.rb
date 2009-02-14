

module Redcar
  class TestingPlugin < Redcar::Plugin
  end
end

load File.dirname(__FILE__) + "/lib/testing.rb"
load File.dirname(__FILE__) + "/lib/runners/rspec/formatters.rb"
load File.dirname(__FILE__) + "/lib/runners/internal_rspec_runner.rb"
load File.dirname(__FILE__) + "/tabs/test_view_tab.rb"

