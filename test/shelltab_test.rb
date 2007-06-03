
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

module Redcar
  class ExampleShellTab < ShellTab
    def initialize(pane)
      @commands = 0
      super("Example Shell Tab\n", pane)
    end
    
    def execute(command)
      @commands += 1
      $just_executed = command
      if command == "test_output"
        output("outputted")
      end
    end
    
    def prompt
      "test:#{@commands}>>"
    end
  end
end

class TestShellTab < Test::Unit::TestCase
  def setup
    startup
    @nt = Redcar.new_tab(Redcar::ExampleShellTab)
    @nt.focus
  end

  def teardown
    shutdown
  end
  
  TEST_BLURB = "Example Shell Tab\n"
  PROMPT_LENGTH = 9
  
  def test_contents
    assert_equal TEST_BLURB+"\ntest:0>>", @nt.contents
  end
  
  def test_execute
    assert_nil $just_executed
    Redcar.keystrokes.issue("f")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("Return")
    assert_equal "foo", $just_executed
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>",
      @nt.contents
  end
  
  def test_left
    assert_equal TEST_BLURB.length+PROMPT_LENGTH, @nt.cursor_offset
    @nt.left
    assert_equal TEST_BLURB.length+PROMPT_LENGTH, @nt.cursor_offset
  end
  
  def test_right
    assert_equal TEST_BLURB.length+PROMPT_LENGTH, @nt.cursor_offset
    @nt.right
    assert_equal TEST_BLURB.length+PROMPT_LENGTH, @nt.cursor_offset
  end
  
  def test_up_with_no_history
    assert_equal TEST_BLURB+"\ntest:0>>",
      @nt.contents
    @nt.up
    assert_equal TEST_BLURB+"\ntest:0>>",
      @nt.contents
  end
  
  def test_down_with_no_history
    assert_equal TEST_BLURB+"\ntest:0>>",
      @nt.contents
    @nt.down
    assert_equal TEST_BLURB+"\ntest:0>>",
      @nt.contents
  end
  
  def test_up_with_history
    Redcar.keystrokes.issue("f")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("Return")
    Redcar.keystrokes.issue("b")
    Redcar.keystrokes.issue("a")
    Redcar.keystrokes.issue("r")
    Redcar.keystrokes.issue("Return")
    
    pre_cursor = @nt.cursor_offset
    assert_equal "bar", $just_executed
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>",
      @nt.contents
    @nt.up
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>bar",
      @nt.contents
    assert_equal pre_cursor+3, @nt.cursor_offset
    3.times do
      @nt.up
      assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>foo",
        @nt.contents
    end
  end
  
  def test_up_and_down_with_history
    Redcar.keystrokes.issue("f")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("o")
    Redcar.keystrokes.issue("Return")
    Redcar.keystrokes.issue("b")
    Redcar.keystrokes.issue("a")
    Redcar.keystrokes.issue("r")
    Redcar.keystrokes.issue("Return")
    Redcar.keystrokes.issue("z")
    assert_equal "bar", $just_executed
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>z",
      @nt.contents
    pre_cursor = @nt.cursor_offset
    @nt.up
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>bar",
      @nt.contents
    assert_equal pre_cursor+2, @nt.cursor_offset
    3.times do
      @nt.up
      assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>foo",
        @nt.contents
    end
    @nt.down
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>bar",
      @nt.contents
    3.times do 
      @nt.down
      assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>z",
        @nt.contents
      assert_equal pre_cursor, @nt.cursor_offset
    end
    @nt.up
    assert_equal TEST_BLURB+"\ntest:0>>foo\ntest:1>>bar\ntest:2>>bar",
      @nt.contents
  end
  
  def test_cannot_enter_text_except_at_prompt
    @nt.cursor=(0)
    assert_equal 0, @nt.cursor_offset
    assert_equal TEST_BLURB+"\ntest:0>>", @nt.contents
    Redcar.keystrokes.issue("a")
    assert_equal TEST_BLURB+"\ntest:0>>", @nt.contents
  end
  
  def test_output
    @nt.insert(@nt.contents.length, "test_output")
    Redcar.keystrokes.issue("Return")
    assert_equal TEST_BLURB+"\ntest:0>>test_output\noutputted\ntest:1>>",
      @nt.contents
  end
end
