

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestSpeedbar < Test::Unit::TestCase
  def setup
    startup
  end
  def teardown
    shutdown
  end
  
  def test_speedbar_build
    speedbar = Redcar::Speedbar.build(:title => "Find",
                                      :buttons => [:find, :ok],
                                      :entry => [
                                                 {:name => :query_string, :type => :text}
                                                ])
    assert speedbar
  end
  
  class Redcar::TextTab
    user_commands do
      def test_speedbar_press_button(arg)
        $test_speedbar_press_button = arg
      end
    end
  end
  
  def test_speedbar_press_button
    speedbar = Redcar::Speedbar.build(:title => "Find",
                                      :buttons => [:find, :ok],
                                      :entry => [
                                                 {:name => :query_string, :type => :text}
                                                ])
    speedbar.on_button(:find) do 
      tab = Redcar.tabs.current
      tab.test_speedbar_press_button("pressed") if tab
    end
    nt = Redcar.new_tab
    nt.focus
    $test_speedbar_press_button = nil
    assert_equal nil, nt.command_history
    speedbar.press_button :find
    assert_equal [[:test_speedbar_press_button, ["pressed"]]], nt.command_history
    assert_equal "pressed", $test_speedbar_press_button
  end
  
  def test_speedbar_focusses_and_accepts_keystrokes
    nt = Redcar.new_tab
    nt.focus
    speedbar = Redcar::Speedbar.build(:title => "Find",
                                      :buttons => [:find, :ok],
                                      :entry => [
                                                 {:name => :query_string, :type => :text}
                                                ])
    speedbar.show
    speedbar.focus(:query_string)
    assert_equal "", speedbar.query_string
    %w{a b c}.each {|l| Redcar.keystrokes.issue l}
    assert_equal "abc", speedbar.query_string
    Redcar.keystrokes.issue "BackSpace"
    assert_equal "ab", speedbar.query_string
  end
end
