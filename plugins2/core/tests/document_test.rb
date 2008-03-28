
module Redcar::Tests
  class DocumentTest < Test::Unit::TestCase
    def setup
      win.tabs.each &:close
      win.new_tab(Redcar::EditTab)
      doc.insert(doc.iter(0), <<-TEXT)
        All of this has happened before,
        and all of it will happen again.
      TEXT
    end
    
    def test_doc
      assert doc == win.tabs.first.document
    end
    
    def test_iter
      assert_equal Gtk::TextIter, doc.iter(1).class
    end
    
    def test_line_start
      assert_equal doc.iter(0), doc.line_start(0)
      assert_equal doc.iter(41), doc.line_start(1)
    end
    
    def test_get_line
      assert_equal("        All of this has happened before,\n",
                   doc.get_line(0))
    end
    
    def test_get_line_default
      doc.cursor = 7
      assert_equal("        All of this has happened before,\n",
                   doc.get_line)
    end
    
    def test_selected?
      doc.text = "foobarbaz"
      assert_equal false, doc.selection?
    end
    
    def test_set_and_get_selection
      doc.text = "foobarbaz"
      doc.select(3, 5)
      assert_equal 3..5, doc.selection_range
    end
    
    def test_replace_line
      doc.text = "foo\nbar\nbaz"
      doc.place_cursor(doc.line_start(0))
      doc.replace_line {|text| text.upcase}
      assert_equal "FOO\nbar\nbaz", doc.text
      doc.replace_line "qux\n"
      assert_equal "qux\nbar\nbaz", doc.text
      doc.place_cursor(doc.line_start(2))
      doc.replace_line {|text| text.upcase}
      assert_equal "qux\nbar\nBAZ", doc.text
    end
    
    def test_replace_selection
      doc.text = "foo\nbar\nbaz"
      doc.select(0, 3)
      assert_equal 0..3, doc.selection_range
      doc.replace_selection{|text| text.upcase}
      assert_equal "FOO\nbar\nbaz", doc.text
      assert_equal 0..3, doc.selection_range
      doc.replace_selection "qux"
      assert_equal "qux\nbar\nbaz", doc.text
      assert_equal 0..3, doc.selection_range
      doc.replace_selection ""
      assert_equal "\nbar\nbaz", doc.text
      assert_equal 0..0, doc.selection_range
      assert !doc.selection?
    end
  end
end
