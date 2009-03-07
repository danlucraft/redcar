
describe Redcar::ProjectTab do
  before(:each) do
    @tab = Redcar::ProjectTab.new
  end

  it "should set the title" do
    @tab.title.should == "Project"
  end

  describe "adding a file", :shared => true do
    before(:each) do
      @tab.add_directory("project", Redcar.PLUGINS_PATH + "/project")
    end
    
    it "should append an iter to the directory" do
      add_file
      @tab.store.contents(1).should include("unknown")
    end
    
    it "should create the file" do
      add_file
      File.exist?(@tab.store.find_iter(1, "unknown")[2]).should be_true
    end
  end

  describe "adding a file" do
    describe "to an open directory by clicking on the file" do
      it_should_behave_like "adding a file"
      
      def add_file
        iter = @tab.store.find_iter(1, "deps.rb")
        @tab.new_file_at(iter[2])
      end
      
      after(:each) do
        FileUtils.rm_f(Redcar.PLUGINS_PATH + "/project/unknown")
      end
    end
    
    describe "to an open directory by clicking on the directory" do
      it_should_behave_like "adding a file"
      
      def add_file
        iter = @tab.store.find_iter(1, "spec")
        @tab.open_row(iter.path)
        iter = @tab.store.find_iter(1, "spec")
        @tab.new_file_at(iter[2])
      end
      
      after(:each) do
        FileUtils.rm_f(Redcar.PLUGINS_PATH + "/project/spec/unknown")
      end
    end
    
    describe "to a closed directory by clicking on the directory" do
      it_should_behave_like "adding a file"
      
      it "should open the directory" do
        add_file
        @tab.store.find_iter(1, "test_spec.rb").should_not be_nil
      end
      
      def add_file
        iter = @tab.store.find_iter(1, "spec")
        @tab.new_file_at(iter[2])
      end
      
      after(:each) do
        FileUtils.rm_f(Redcar.PLUGINS_PATH + "/project/spec/unknown")
      end
    end
  end
end

