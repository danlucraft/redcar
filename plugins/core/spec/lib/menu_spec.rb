
describe Redcar::Menu do
  before(:each) do
    Redcar::CloseAllTabs.new.do
  end
  
  after(:each) do
    Redcar::CloseAllTabs.new.do
  end
  
  describe "multiple options menu" do
    before(:each) do
      Redcar::NewTab.new.do
      options = [Redcar::NewTab, Redcar::Copy].map do |com|
        name = (com.get(:name) || com.to_s.split("::").last)
        [com.get(:icon), name, com]
      end
      bus("/redcar/services/context_menu_options_popup/").call(options)
      @menu = bus['/redcar/gtk/context_options_menu/'].data
    end

    def press(gtk_, val)
      key = Gdk::EventKey.new(Gdk::Event::KEY_RELEASE)
      key.keyval = Gdk::Keyval.from_name(val)
      gtk_.signal_emit("key-press-event", key)
    end

    it "should execute the selected command" do
      press(@menu, "1")
      Redcar.win.tabs.length.should == 2
    end
  end
end
