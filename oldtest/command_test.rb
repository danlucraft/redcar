

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'
require 'benchmark'

KeyBinding = Redcar::KeyBinding
Keymap     = Redcar::Keymap

class TestCommand < Test::Unit::TestCase
  
  include Keymap
  
  # needed so that the command dispatcher doesn't
  # send any keymaps here
  attr_accessor :widget
  
  def setup
    startup
    @widget = nil 
  end
  
  def teardown
    shutdown
  end
  
  def test_keybinding_parse
    assert_equal KeyBinding.new([], "x"),
                 KeyBinding.parse("x")
    assert_equal KeyBinding.new([:control, :alt], "X"),
                 KeyBinding.parse("control-alt X")
    assert_equal KeyBinding.new([:control, :alt], "x"),
                 KeyBinding.parse("alt-control x")
    assert_equal KeyBinding.new([:control, :alt], "x"),
                 KeyBinding.parse("alt-Control x")
    assert_equal KeyBinding.new([:control, :alt], "x"),
                 KeyBinding.parse("a-c x")
    assert_equal KeyBinding.new([:control, :alt], "x"),
                 KeyBinding.parse("alt-Ctrl x")
    assert_equal KeyBinding.new([:control], "space"),
                 KeyBinding.parse("control space")
  end
  
  def test_keymap_set_key
    self.class.class_eval do
      keymap "x",          :insert, "x"
      keymap /^(.)$/,      :insert, '\1'
      keymap /^shift (.)$/,      :insert, '\1'
      keymap /^caps (.)$/,      :insert, '\1'
      keymap KeyBinding.parse("ctrl x"), :cut
    end
    
    a, b, c = nil, nil, nil
    
    assert_equal [:insert, ["X"]],  get_keymap("shift X")
    assert_equal [:cut, []],        get_keymap("ctrl x")
    assert_equal [:insert, ["B"]],  get_keymap("caps B")
    assert_equal [:insert, ["a"]],  get_keymap("a")
  end
  
  def test_issue_from_keybinding
    nt = Redcar.new_tab
    nt.focus
    assert_equal "", nt.contents
    Redcar.keystrokes.issue_from_keybinding("shift A")
    assert_equal "A", nt.contents
  end
  
  def test_keystroke_history
    self.class.class_eval do
      keymap "x",          :insert, "x"
    end
    Redcar.keystrokes.issue_from_keybinding("x")
    Redcar.keystrokes.issue_from_keybinding("ctrl G")
    Redcar.keystrokes.issue_from_keybinding("x")
    assert_equal 2, Redcar.keystrokes.history.length
  end
  
  def test_issue_from_eventkey
    nt = Redcar.new_tab
    nt.focus
    assert_equal "", nt.contents
    gdk_eventkey = Gdk::EventKey.new(Gdk::Event::KEY_PRESS)
    modshift = Gdk::Window::ModifierType.new(Gdk::Window::SHIFT_MASK)
    gdk_eventkey.state = modshift
    gdk_eventkey.keyval = Gdk::Keyval.from_name("a")
    Redcar.keystrokes.issue_from_gdk_eventkey(gdk_eventkey)
    assert_equal "a", nt.contents
  end

  class TestFAK
    include Redcar::Keymap
    keymap "control-shift p", :foobar
  end
  
  def test_find_all_keymaps
    a = 5.times { TestFAK.new }
    assert_equal 5, Keymap.find_all_keymaps("control-shift p").length
  end
  
  # this whole thing is by way of demonstrating that the slowness
  # that occurs when typing characters FAST with the shift key down
  # isn't in my code. Final proof, gedit has it too.
  def stest_speed
    nt = Redcar.new_tab
    nt.focus
    nt.widget.show_all
    assert_equal "", nt.contents
    
    gdk_eventkey = Gdk::EventKey.new(Gdk::Event::KEY_PRESS)
    modshift = Gdk::Window::ModifierType.new(Gdk::Window::SHIFT_MASK)
    modlock = Gdk::Window::ModifierType.new(Gdk::Window::LOCK_MASK)
    enter = Gdk::EventKey.new(Gdk::Event::KEY_PRESS)
    enter.keyval = Gdk::Keyval.from_name("Return")
    puts
    Benchmark::bm(11) do |bm|
      gdk_eventkey.state = Gdk::Window::ModifierType.new
      gdk_eventkey.keyval = Gdk::Keyval.from_name("a")
      bm.report("lowercase:") do
        100.times do
          10.times do
            Redcar.keystrokes.issue_from_gdk_eventkey(gdk_eventkey)
            nt.replace("")
          end
        end
      end
      bm.report("shift:" ) do
        gdk_eventkey.state = modshift
        gdk_eventkey.keyval = Gdk::Keyval.from_name("A")
        100.times do
          10.times do
            Redcar.keystrokes.issue_from_gdk_eventkey(gdk_eventkey)
            nt.replace("")
          end
        end
      end
      bm.report("caps:" ) do
        gdk_eventkey.keyval = Gdk::Keyval.from_name("A")
        gdk_eventkey.state = modlock
        100.times do
          10.times do
            Redcar.keystrokes.issue_from_gdk_eventkey(gdk_eventkey)
            nt.replace("")
          end
        end
      end
    end
  end
  
#   class TestIL
#     include Redcar::Keymap
#     keymap "control-shift p", :foobarbaz
#   end
  
#   def test_insert_listener
#     class << Redcar.GlobalKeymap
#       keymap "control-shift p", :foobarbazqux
#     end
#     obj = TestIL.new
#     obj.

#   end
end
