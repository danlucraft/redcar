
require File.join(File.dirname(__FILE__), *%w".. spec_helper")

FileList = Redcar::Project::FileList

describe FileList do
  def fixture_path
    File.expand_path(File.join(File.dirname(__FILE__), *%w".. fixtures myproject"))
  end
  
  def relative_path(*path)
    File.join(fixture_path, *path)
  end
  
  before do
    @file_list = FileList.new(fixture_path)
  end
  
  it "should return an empty list initially" do
    @file_list.all_files.should be_empty
  end
  
  describe "file list" do
    before do
      @file_list.update
    end
    
    it "should return a list of files in the directory" do
      @file_list.all_files.include?(relative_path("README")).should be_true
      @file_list.all_files.include?(relative_path("lib", "foo_lib.rb")).should be_true
      @file_list.all_files.length.should == 3
    end
  end
  
  describe "update information" do
    before do
      @dirname = "project_spec_testdir"
      @files = {"Carnegie"    => "steel", 
                "Rockefeller" => "oil",
                "subdir"      => {
                  "Ford" => "cars"
                }}
      write_dir_contents(@dirname, @files)
      @file_list = FileList.new(@dirname)
      @file_list.update
      p @file_list.all_files
    end
    
    after do
      FileUtils.rm_r(@dirname)
    end
    
    describe "after files have been added" do
      before do
        write_file(@dirname, "Branson", "balloons")
        @file_name = File.expand_path(File.join(@dirname, "Branson"))
      end
      
      it "should add the file to the list" do
        @file_list.update
        @file_list.all_files.include?(@file_name).should be_true
      end
      
      it "should report on the added files" do
        @file_list.update.include?(@file_name).should be_true
      end
    end
  end
end










