
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/redcar.rb'
require File.dirname(__FILE__) + '/test_helper'

class TestMenus < Test::Unit::TestCase
  def setup
    startup
  end
  
  def teardown
    shutdown
  end

  def test_menu_item_works
    command_run = false
    Redcar.menu "Test Menu" do |menu|
      menu.command "Test Command 1", :test_command_1, nil, "control 1" do |pane, tab|
        command_run = true
      end
    end
    Redcar.keystrokes.issue("control 1")
    assert command_run
  end
end
