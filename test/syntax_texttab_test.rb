
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestSyntaxTextTab < Test::Unit::TestCase
  include Redcar
  include Redcar::Syntax
  
  def setup
    startup
    @nt = Redcar.new_tab
    @nt.focus
    @source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    @nt.set_syntax('Ruby')
    @nt.replace(@source[0..-2]) # remove the last "\n"
    run_gtk
  end
  
  def teardown
    shutdown
  end
  
  def test_insertion_in_line
    pre = @nt.scope_tree.children[3].end.offset
    @nt.insert(TextLoc.new(3, 20), "foo")
    run_gtk
    new_source=<<BSTR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:outpfoout => :silent)
Gtk.main
BSTR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal pre+3, @nt.scope_tree.children[3].end.offset
  end
  
  def test_insertion_in_line2
    assert_equal 6, @nt.scope_tree.children.length
    @nt.insert(TextLoc.new(4, 8), " :foo")
    run_gtk
    new_source=<<CSTR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main :foo
CSTR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal 7, @nt.scope_tree.children.length
    assert_equal("constant.other.symbol.ruby", 
                 @nt.scope_tree.children.last.name)
  end
  
  def test_insert_lines
    assert_equal 6, @nt.scope_tree.children.length
    @nt.insert(TextLoc.new(3, 14), "\nclass Red; attr :foo; end\nFile.rm")
    run_gtk
    new_source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup
class Red; attr :foo; end
File.rm(:output => :silent)
Gtk.main
STR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal 11, @nt.scope_tree.children.length
  end
  
  def test_return_at_end
    pre = @nt.scope_tree.copy
    @nt.insert(TextLoc.new(4, 8), "\n")
    run_gtk
    new_source=<<CSTR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main

CSTR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal 6, @nt.parser.text.length
    assert @nt.scope_tree.identical?(pre)
  end
  
  def test_return_in_middle
    pre = @nt.scope_tree.copy
    pre.shift_after(3, 3)
    @nt.insert(TextLoc.new(3, 0), "\n")
    run_gtk
    @nt.insert(TextLoc.new(4, 0), "\n")
    run_gtk
    @nt.insert(TextLoc.new(5, 0), "\n")
    run_gtk
    new_source=<<CSTR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'



Redcar.startup(:output => :silent)
Gtk.main
CSTR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal 8, @nt.parser.text.length
    assert @nt.scope_tree.identical?(pre)
  end
  
  def test_delete_in_line
    pre = @nt.scope_tree.copy
    pre.shift_chars(3, -3, 18)
    pre.children[3].open_matchdata = ":out"
    @nt.delete(TextLoc.new(3, 18), TextLoc.new(3, 21))
    run_gtk
    new_source=<<BSTR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:out => :silent)
Gtk.main
BSTR
    assert_equal new_source[0..-2], @nt.contents
    assert @nt.scope_tree.identical?(pre)
  end
  
  def test_delete_return
    pre = @nt.scope_tree.copy
    pre.shift_after(1, -1)
    @nt.delete(TextLoc.new(0, 20), TextLoc.new(1, 0))
    run_gtk
    new_source=<<BSTR
#! /usr/bin/env ruby
require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
BSTR
    assert_equal new_source[0..-2], @nt.contents
    assert @nt.scope_tree.identical?(pre)
  end
  
  def test_delete_multiple_lines
    pre = @nt.scope_tree.copy
    @nt.delete(TextLoc.new(0, 7), TextLoc.new(3, 9))
    
    run_gtk
    new_source=<<BSTR
#! /usrartup(:output => :silent)
Gtk.main
BSTR
    assert_equal new_source[0..-2], @nt.contents
    p @nt.parser.text
    assert_equal 2, @nt.parser.text.length
    assert_equal 2, @nt.scope_tree.children.length
  end
  
  def __test_bug
    assert_equal 6, @nt.scope_tree.children.length
    %w(p u t s " h i ").each_with_index do |l, i|
      @nt.insert(TextLoc.new(1, i), l)
    end
    run_gtk
    new_source=<<CSTR
#! /usr/bin/env ruby
puts "hi"
require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
CSTR
    assert_equal new_source[0..-2], @nt.contents
    assert_equal 7, @nt.scope_tree.children.length
  end
end
