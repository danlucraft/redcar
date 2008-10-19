
describe Redcar::FindFileDialog do
  describe "creation" do
    before(:each) do
      @dialog = Redcar::FindFileDialog.new
    end

    it "should create a @dialog" do
      @dialog.show
      @dialog.destroy
    end
    
    it "should have a text entry and a list" do
      child_classes = @dialog.vbox.children.map(&:class)
      child_classes.should include(Gtk::Entry)
      child_classes.should include(Gtk::TreeView)
    end

    it "should have an empty list" do
      @dialog.list.should be_empty
    end
  end

  describe ".find_files" do
    before(:each) do
      @fs = Redcar::FindFileDialog.find_files("spc", Redcar::ROOT + "/plugins2/project/")
      @names = @fs.map {|fn| fn.split("/").last }
    end

    it "should find files" do
      @names.should include("find_file_dialog_spec.rb")
    end

    it "should return them in the right order" do
      i1 = @names.index("find_file_dialog_spec.rb")
      i2 = @names.index("project_tab_spec.rb")
      i1.should > i2
    end
  end
end
