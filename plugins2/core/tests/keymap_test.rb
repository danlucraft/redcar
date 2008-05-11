
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

    class KeymapTestCommand2 < Redcar::Command
      def execute
        Redcar::Tests::KeymapTest.test_var *= 10
      end
    end

    def setup
      Redcar::Keymap.unregister_key("Ctrl+G")
    end

    def win
      Redcar::App.focussed_window
    end

    def test_clean_letter
      assert_equal "Page_Up", Redcar::Keymap.clean_letter("Page Up")
    end

    def test_register_key
      assert_nil bus("/redcar/keymaps/Ctrl+G").data
      Redcar::Keymap.register_key_command("Ctrl+G", KeymapTestCommand)
      assert_not_nil bus("/redcar/keymaps/Ctrl+G").data
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
      self.class.test_var = 2
      Redcar::Keymap.register_key_command("Ctrl+G", KeymapTestCommand)
      Redcar::Keymap.execute_key("Ctrl+G")
      assert_equal 4, self.class.test_var
      Redcar::Keymap.unregister_key("Ctrl+G")
    end
    
    def test_multiple_commands_for_keymap
      Redcar.win.new_tab(Redcar::EditTab)
      Redcar::Keymap.register_key_command("Ctrl+G", KeymapTestCommand)
      Redcar::Keymap.register_key_command("Ctrl+G", KeymapTestCommand2)
      Redcar::Menu.expects(:context_menu_options_popup).with([[nil, "KeymapTestCommand", KeymapTestCommand],
                                                              [nil, "KeymapTestCommand2", KeymapTestCommand2]])
      Redcar::Keymap.execute_key("Ctrl+G")
    end
  end
end
