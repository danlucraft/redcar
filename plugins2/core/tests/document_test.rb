
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
  end
end
