
module Redcar::Tests
  class CommandTest < Test::Unit::TestCase
    class << self
      attr_accessor :test_var
    end

    Redcar::Sensitive.register(:test_2_tabs, [:new_tab, :close_tab]) do
      Redcar.win and Redcar.win.tabs.length > 1
    end

    Redcar::Sensitive.register(:test_1_tab, [:new_tab, :close_tab]) do
      Redcar.win and Redcar.win.tabs.length > 0
    end

    class TestCommand1 < Redcar::Command
      menu "RedcarTestMenu/TestCommand1"
      key  "Global/Ctrl+Super+Alt+Shift+5"

      def initialize(val)
        @val = val
      end

      def execute
        Redcar::Tests::CommandTest.test_var *= @val
      end
    end

    class TestSensitiveCommand < Redcar::Command
      sensitive :test_2_tabs

      def execute
      end
    end

    class TestSensitiveCommand2 < TestSensitiveCommand
      sensitive :test_1_tab

      def execute
      end
    end

    class TestPythonCommand < Redcar::EditTabCommand
      scope "source.python"
    end

    class TestPythonStringCommand < TestPythonCommand
      scope "source.python string"
    end

    class TestPythonScopeInheritsCommand < TestPythonCommand
    end

    class TestRangeTab < Redcar::Tab
      def initialize(pane)
        super pane, Gtk::Label.new("foo")
      end
    end

    class TestRangeCommand < Redcar::Command
      range TestRangeTab
    end

    class TestRangeInheritsCommand < TestRangeCommand
    end

    def test_execute
      CommandTest.test_var = 2
      TestCommand1.new(10).do
      assert_equal 20, CommandTest.test_var
    end

    def test_added_to_databus
      assert bus("/redcar/commands/").has_child?("Redcar::Tests::CommandTest::TestCommand1")
    end

    def test_added_to_menu
      assert bus("/redcar/menus/menubar/RedcarTestMenu/").has_child?("TestCommand1")
    end

    def test_added_to_keymap
      assert bus("/redcar/keymaps/Global/").has_child?("Ctrl+Super+Alt+Shift+5")
    end

    def test_sensitivity
      Redcar.win.tabs.each &:close
      assert !TestSensitiveCommand.active?
      2.times { Redcar.win.new_tab(Redcar::Tab, Gtk::Label.new("foo")) }
      assert TestSensitiveCommand.active?
    end

    def test_operative
      Redcar.win.tabs.each &:close
      assert !TestSensitiveCommand.operative?
      2.times { Redcar.win.new_tab(Redcar::Tab, Gtk::Label.new("foo")) }
      assert TestSensitiveCommand.operative?
    end

    def test_operative_inherits
      Redcar.win.tabs.each &:close
      assert !TestSensitiveCommand.active?
      assert !TestSensitiveCommand2.active?
      assert !TestSensitiveCommand.operative?
      assert !TestSensitiveCommand2.operative?
      Redcar.win.new_tab(Redcar::Tab, Gtk::Label.new("foo"))
      assert !TestSensitiveCommand.active?
      assert TestSensitiveCommand2.active?
      assert !TestSensitiveCommand.operative?
      assert !TestSensitiveCommand2.operative?
      Redcar.win.new_tab(Redcar::Tab, Gtk::Label.new("foo"))
      assert TestSensitiveCommand.active?
      assert TestSensitiveCommand2.active?
      assert TestSensitiveCommand.operative?
      assert TestSensitiveCommand2.operative?
    end

    def test_scope_sensitivity
      Redcar.win.tabs.each &:close
      assert !TestPythonCommand.executable?
      assert !TestPythonScopeInheritsCommand.executable?
      assert !TestPythonStringCommand.executable?
      Redcar.win.new_tab(Redcar::EditTab)
      assert !TestPythonCommand.executable?(Redcar.tab)
      assert !TestPythonScopeInheritsCommand.executable?(Redcar.tab)
      assert !TestPythonStringCommand.executable?(Redcar.tab)
      puts
      (t1 = Redcar.tab).syntax = 'Python'
      t2 = Redcar.tab
      assert TestPythonCommand.executable?(t2)
      assert TestPythonScopeInheritsCommand.executable?(Redcar.tab)
      assert !TestPythonStringCommand.executable?(Redcar.tab)
      Redcar.doc.text = "  \"Tigh me up, Tigh me down\"  "
      Redcar.doc.place_cursor(Redcar.doc.iter(6))
      assert TestPythonCommand.executable?(Redcar.tab)
      assert TestPythonScopeInheritsCommand.executable?(Redcar.tab)
      assert TestPythonStringCommand.executable?(Redcar.tab)
    end

    def test_range
      Redcar.win.tabs.each &:close
      assert !TestRangeCommand.executable?
      assert !TestRangeInheritsCommand.executable?
      Redcar.win.new_tab(Redcar::EditTab)
      assert !TestRangeCommand.executable?(Redcar.tab)
      assert !TestRangeInheritsCommand.executable?(Redcar.tab)
      Redcar.win.tabs.each &:close
      Redcar.win.new_tab(TestRangeTab)
      assert TestRangeCommand.executable?(Redcar.tab)
      assert TestRangeInheritsCommand.executable?(Redcar.tab)
    end

    def test_range2
      Redcar.win.tabs.each &:close
      assert !Redcar::StandardMenus::CloseTab.in_range?
      assert !Redcar::StandardMenus::CloseTab.executable?
      Redcar.win.new_tab(Redcar::EditTab)
      assert Redcar::StandardMenus::CloseTab.in_range?
      assert Redcar::StandardMenus::CloseTab.executable?
    end
  end
end
