
require 'mocha'

module Redcar::Tests
  class KeymapTest < Test::Unit::TestCase
    class << self
      attr_accessor :test_var
    end
    
    class KeymapTestCommand < Redcar::Command
      def execute
        Redcar::Tests::KeymapTest.test_var *= 2
      end
    end
    
    def test_clean_letter
      assert_equal "Page_Up", Redcar::Keymap.clean_letter("Page Up")
    end
    
    def test_register_key
      assert_nil bus("/redcar/keymaps/KeymapTest/Ctrl+G").data
      com = Redcar::InlineCommand.new
      Redcar::Keymap.register_key("KeymapTest/Ctrl+G", com)
      assert_not_nil bus("/redcar/keymaps/KeymapTest/Ctrl+G").data
    end
    
    def test_process
      gdk_eventkey = Gdk::EventKey.new(Gdk::Event::KEY_RELEASE)
      # should automatically remove this mask:
      gdk_eventkey.state = gdk_eventkey.state | Gdk::Window::MOD2_MASK
      gdk_eventkey.state = gdk_eventkey.state | Gdk::Window::CONTROL_MASK
      gdk_eventkey.keyval = 103
      Redcar::Keymap.expects(:execute_key).with("Ctrl+G")
      Redcar::Keymap.process(gdk_eventkey)
    end
    
    def test_execute_key
      Redcar::Keymap.expects(:execute_key_on_keymap).
        with("Ctrl+G", "Global")
      Redcar::Keymap.execute_key("Ctrl+G")
    end
    
    def test_execute_key_multiple_keymaps
      Redcar::Keymap.push_onto(win, "KeymapTest")
      Redcar::Keymap.push_onto(win, "KeymapTest2")
      Redcar::Keymap.expects(:execute_key_on_keymap).
        with("Ctrl+G", "KeymapTest2")
      Redcar::Keymap.expects(:execute_key_on_keymap).
        with("Ctrl+G", "KeymapTest")
      Redcar::Keymap.expects(:execute_key_on_keymap).
        with("Ctrl+G", "Global")
      Redcar::Keymap.execute_key("Ctrl+G")
      Redcar::Keymap.remove_from(win, "KeymapTest")
      Redcar::Keymap.remove_from(win, "KeymapTest2")
    end
    
    def test_execute_key_on_keymap
      Redcar::Keymap.push_onto(win, "KeymapTest")
      self.class.test_var = 2
      com = KeymapTestCommand.new
      Redcar::Keymap.register_key("KeymapTest/Ctrl+G", com)
      Redcar::Keymap.execute_key_on_keymap("Ctrl+G", "KeymapTest")
      assert_equal 4, self.class.test_var
      Redcar::Keymap.unregister_key("KeymapTest/Ctrl+G")
      Redcar::Keymap.remove_from(win, "KeymapTest")
    end
  end
end
