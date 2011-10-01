require "spec_helper"

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
      
      describe "top level contents" do
        it "the nodes are the contents of the directory" do
          top_nodes = @mirror.top
          top_nodes.length.should == 3
          top_nodes.map {|n| n.text}.should == %w(subdir Carnegie Rockefeller)
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
        
        it "isn't changed after you have got the top nodes" do
          @mirror.top
          @mirror.changed?.should be_false
        end
        
        describe "sub directory contents" do
          it "the nodes return their children" do
            subdir_node = @mirror.top.detect {|n| n.text == "subdir"}
            sub_nodes = subdir_node.children
            sub_nodes.length.should == 1
            sub_nodes.map {|n| n.text}.should == %w(Ford)
          end
        end
      end
    end
    
    after do
      FileUtils.rm_r(@dirname)
    end
    
  end
end