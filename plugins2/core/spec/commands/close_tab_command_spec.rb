
describe Redcar::CloseTab do
  before(:each) do
    Redcar::CloseAllTabs.new.do
  end

  after(:each) do
    Redcar::CloseAllTabs.new.do
  end

  describe "closing" do
    it "should close the right tab" do
      t1 = Redcar.win.new_tab(Redcar::Tab, Gtk::Button.new)
      t2 = Redcar.win.new_tab(Redcar::Tab, Gtk::Button.new)
      t3 = Redcar.win.new_tab(Redcar::Tab, Gtk::Button.new)
      t1.title = "test1"
      t2.title = "test2"
      t3.title = "test3"
      t3.focus
      Redcar.win.tabs.map{|t| t.label.text}.should == %w(test1 test2 test3)
      Redcar::CloseTab.new(Redcar.win.tab["test1"]).do
      Redcar.win.tabs.map{|t| t.label.text}.should == %w(test2 test3)
    end
  end
end
