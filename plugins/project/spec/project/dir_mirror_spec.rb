require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Redcar::Project
  describe DirMirror do
    before do
      @dirname = "project_spec_testdir"
      @files = {"Carnegie"    => "steel", 
                "Rockefeller" => "oil",
                "subdir"      => {
                  "Ford" => "cars"
                }}
      write_dir_contents(@dirname, @files)
      @mirror = DirMirror.new(File.expand_path(@dirname))
    end

    describe "for a directory" do
    
      it "tells you the directory exists" do
        @mirror.exists?.should be_true
      end
      
      it "tells you it has changed" do
        @mirror.changed?.should be_true
      end
      
      describe "contents" do
        it "the top nodes are the contents of the directory" do
          top_nodes = @mirror.top
          top_nodes.length.should == 3
          top_nodes.map {|n| n.text}.should == %w(Carnegie Rockefeller subdir)
        end
        
        it "files are leaf nodes" do
          top_nodes = @mirror.top
          top_nodes.detect {|n| n.text == "Carnegie"}.leaf?.should be_true
          top_nodes.detect {|n| n.text == "Rockefeller"}.leaf?.should be_true
        end
        
        it "subdirectories are not leaf nodes" do
          top_nodes = @mirror.top
          top_nodes.detect {|n| n.text == "subdir"}.leaf?.should be_false
        end
      end
    end
    
    after do
      FileUtils.rm_r(@dirname)
    end
    
    def write_dir_contents(dirname, files)
      FileUtils.mkdir_p(dirname)
      files.each do |filename, contents|
        if contents.is_a?(Hash)
          write_dir_contents(dirname + "/" + filename, contents)
        else
          File.open(dirname + "/" + filename, "w") {|f| f.print contents}
        end
      end
    end
    
  end
end