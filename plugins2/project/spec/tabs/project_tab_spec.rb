
describe Redcar::ProjectTab do
  before(:each) do
    @tab = Redcar.win.new_tab(Redcar::ProjectTab)
    @tab.clear
  end

  after(:each) do
    @tab.close
  end

  it "should set the title" do
    @tab.title.should == "Project"
  end

  describe "adding a project directory" do
    before(:each) do
      @tab.add_directory("project", Redcar.PLUGINS_PATH + "/project")
    end

    it "should add the files" do
      @tab.store.contents(2).should include(Redcar.PLUGINS_PATH + "/project/spec")
    end

    it "should not add sub directories" do
      @tab.store.contents(2).should_not include(Redcar.PLUGINS_PATH + "/project/spec/tabs")
    end

    it "should have short names for files" do
      @tab.store.contents(1).should include("spec")
    end

    it "should create dummy rows under directories (so the open arrow appears)" do
      @tab.store.contents(1).should include("[dummy row]")
      @tab.store.contents(2).should include(Redcar.PLUGINS_PATH + "/project/spec/[dummy row]")
    end

    it "should have the directory" do
      @tab.directories.should include(Redcar.PLUGINS_PATH + "/project")
    end
  end

  describe "opening a directory by activating the row" do
    before(:each) do
      @tab.add_directory("project", Redcar.PLUGINS_PATH + "/project")
      i = @tab.store.find_iter(1, "spec")
      @tab.view.selection.select_iter(i)
      @tab.view.signal_emit(:row_activated, i.path, @tab.view.columns[1])
    end

    it "should add subdirectories" do
      @tab.store.contents(2).should include(Redcar.PLUGINS_PATH + "/project/spec/tabs")
    end

    it "should only add directories once" do
      i = @tab.store.find_iter(1, "spec")
      @tab.view.selection.select_iter(i)
      @tab.view.signal_emit(:row_activated, i.path, @tab.view.columns[1])
      @tab.store.contents(2).scan("/project/spec/tabs\n").length.should == 1
    end

    it "should remove the dummy row" do
      @tab.store.contents(2).should_not include(Redcar.PLUGINS_PATH + "/project/spec/[dummy row]")
    end
  end

  describe "opening a directory by expanding the row" do
    before(:each) do
      @tab.add_directory("project", Redcar.PLUGINS_PATH + "/project")
      i = @tab.store.find_iter(1, "spec")
      @tab.view.selection.select_iter(i)
      @tab.view.signal_emit(:row_expanded, i, i.path)
    end

    it "should add subdirectories" do
      @tab.store.contents(2).should include(Redcar.PLUGINS_PATH + "/project/spec/tabs")
    end

    it "should only add directories once" do
      i = @tab.store.find_iter(1, "spec")
      @tab.view.selection.select_iter(i)
      @tab.view.signal_emit(:row_expanded, i, i.path)
      @tab.store.contents(2).scan("/project/spec/tabs\n").length.should == 1
    end

    it "should remove the dummy row" do
      @tab.store.contents(2).should_not include(Redcar.PLUGINS_PATH + "/project/spec/[dummy row]")
    end
  end
end
