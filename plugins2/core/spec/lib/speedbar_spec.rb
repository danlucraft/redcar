
describe Redcar::Speedbar do
  before(:each) do
    Redcar::CloseAllTabs.new.do
  end
  
  after(:each) do
    Redcar::CloseAllTabs.new.do
  end
  
  class TestSpeedbarFind < Redcar::Speedbar
    label "Find:"
    textbox :query_string
    button "Go", nil, "Return" do |sb|
      $find_call = sb
    end
  end
  
  it "should attach a speedbar to a tab" do
    sp = TestSpeedbarFind.instance
    Redcar.win.new_tab(Redcar::Tab, Gtk::Button.new("foo"))
    sp.show(Redcar.tab)
  end
end
