

describe Redcar::EditView::AutoPairer do
  before(:each) do
    @buf = Redcar::Document.new
    @buf.set_grammar_by_name("Ruby")
	  @autopairer = Redcar::EditView::AutoPairer.new(@buf)
    @old_pref1 = Redcar::Preference.get("Editing/Indent size")
    @old_pref2 = Redcar::Preference.get("Editing/Use spaces instead of tabs")
    Redcar::Preference.set("Editing/Indent size", 1)
    Redcar::Preference.set("Editing/Use spaces instead of tabs", false)
  end

  it "should insert pair end" do
    @buf.text = "pikon"
    @buf.place_cursor(@buf.line_end1(0))
    @buf.insert_at_cursor("(")
    @buf.text.should == "pikon()"
    @buf.cursor_offset.should == 6
    @autopairer.mark_pairs.length.should == 1
  end
  
  it "should delete pair end when pair start deleted" do
    @buf.text = "pikon"
    @buf.place_cursor(@buf.line_end1(0))
    @buf.insert_at_cursor("(")
    @buf.text.should == "pikon()"
    @buf.delete(@buf.iter(5), @buf.iter(6))
    @buf.text.should == "pikon"
    @buf.cursor_offset.should == 5
    @autopairer.mark_pairs.length.should == 0
  end
  
  it "should allow for typeover of end" do
    @buf.text = "pikon"
    @buf.place_cursor(@buf.line_end1(0))
    @buf.insert_at_cursor("(")
    @buf.insert_at_cursor("h")
    @buf.insert_at_cursor("i")
    @buf.insert_at_cursor(")")
    @buf.text.should == "pikon(hi)"
    @buf.cursor_offset.should == 9
    @autopairer.mark_pairs.length.should == 0
  end
  
  it "should only allow typeover of the correct end" do
    @buf.text = "pikon"
    @buf.place_cursor(@buf.line_end1(0))
    @buf.insert_at_cursor("(")
    @buf.insert_at_cursor("h")
    @buf.insert_at_cursor("i")
    @buf.insert_at_cursor("\"")
    @buf.text.should == "pikon(hi\"\")"
    @buf.cursor_offset.should == 9
    @autopairer.mark_pairs.length.should == 2
  end
  
  it "should forget about pairs if the user navigates outside of the pair width" do
    @buf.text = "pikon"
    @buf.place_cursor(@buf.line_end1(0))
    @buf.insert_at_cursor("(")
    @buf.insert_at_cursor("h")
    @buf.place_cursor(@buf.line_start(0))
    @buf.place_cursor(@buf.iter(7))
    @buf.insert_at_cursor(")")
    @buf.text.should == "pikon(h))"
    @buf.cursor_offset.should == 8
    @autopairer.mark_pairs.should be_empty
  end
    
  it "should see scope pairs" do
    @buf = Redcar::Document.new
    @buf.set_grammar_by_name("HTML")
    @autopairer = Redcar::EditView::AutoPairer.new(@buf)
    @buf.insert_at_cursor("<")
    @buf.text.should == "<>"
  end

# TODO: fix me    
#   it "should see scope pairs in embedded" do
#     @buf.text = "f=<<-HTML\n"
#     @buf.insert_at_cursor("<")
#     @buf.text.should == "f=<<-HTML\n<>"
#   end
    
  it "should see Ruby scope pairs" do
    @buf.text = "foo do \n"
    @buf.place_cursor(@buf.iter(7))
    @buf.insert_at_cursor("|")
    @buf.text.should == "foo do ||\n"
    @buf.cursor_offset.should == 8
  end
    
  after(:each) do
    Redcar::Preference.set("Editing/Indent size", @old_pref1)
    Redcar::Preference.set("Editing/Use spaces instead of tabs", @old_pref2)
  end
end
