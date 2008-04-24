
module Redcar::Tests
  class DocumentTest < Test::Unit::TestCase
    def setup
      Redcar.win.tabs.each &:close
      Redcar.win.new_tab(Redcar::EditTab)
      Redcar.doc.insert(Redcar.doc.iter(0), <<-TEXT)
        All of this has happened before,
        and all of it will happen again.
      TEXT
    end
    
    def test_doc
      assert Redcar.doc == Redcar.win.tabs.first.document
    end
    
    def test_iter
      assert_equal Gtk::TextIter, Redcar.doc.iter(1).class
    end
    
    def test_line_start
      assert_equal Redcar.doc.iter(0), Redcar.doc.line_start(0)
      assert_equal Redcar.doc.iter(41), Redcar.doc.line_start(1)
    end
    
    def test_get_line
      assert_equal("        All of this has happened before,\n",
                   Redcar.doc.get_line(0))
    end
    
    def test_get_line_default
      Redcar.doc.cursor = 7
      assert_equal("        All of this has happened before,\n",
                   Redcar.doc.get_line)
    end
    
    def test_selected?
      Redcar.doc.text = "foobarbaz"
      assert_equal false, Redcar.doc.selection?
    end
    
    def test_set_and_get_selection
      Redcar.doc.text = "foobarbaz"
      Redcar.doc.select(3, 5)
      assert_equal 3..5, Redcar.doc.selection_range
    end
    
    def test_replace_line
      Redcar.doc.text = "foo\nbar\nbaz"
      Redcar.doc.place_cursor(Redcar.doc.line_start(0))
      Redcar.doc.replace_line {|text| text.upcase}
      assert_equal "FOO\nbar\nbaz", Redcar.doc.text
      Redcar.doc.replace_line "qux\n"
      assert_equal "qux\nbar\nbaz", Redcar.doc.text
      Redcar.doc.place_cursor(Redcar.doc.line_start(2))
      Redcar.doc.replace_line {|text| text.upcase}
      assert_equal "qux\nbar\nBAZ", Redcar.doc.text
    end
    
    def test_replace_selection
      Redcar.doc.text = "foo\nbar\nbaz"
      Redcar.doc.select(0, 3)
      assert_equal 0..3, Redcar.doc.selection_range
      Redcar.doc.replace_selection{|text| text.upcase}
      assert_equal "FOO\nbar\nbaz", Redcar.doc.text
      assert_equal 0..3, Redcar.doc.selection_range
      Redcar.doc.replace_selection "qux"
      assert_equal "qux\nbar\nbaz", Redcar.doc.text
      assert_equal 0..3, Redcar.doc.selection_range
      Redcar.doc.replace_selection ""
      assert_equal "\nbar\nbaz", Redcar.doc.text
      assert_equal 0..0, Redcar.doc.selection_range
      assert !Redcar.doc.selection?
    end
  end
end
