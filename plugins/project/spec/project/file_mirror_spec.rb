require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Redcar::Project
  describe FileMirror do
    def write_testfile_contents(val)
      File.open(@filename, "wb") {|f| f.print val}
    end
    
    before do
      @filename = "project_spec_testfile"
      write_testfile_contents("wintersmith")
      @mirror = FileMirror.new(@filename)
    end
    
    after do
      FileUtils.rm(@filename)
    end
    
    describe "for a test file" do
      it "tells you it exists" do
        @mirror.exists?.should be_true
      end
      
      it "tells you it has changed" do
        @mirror.changed?.should be_true
      end
      
      it "lets you get the contents of the file" do
        @mirror.read.should == "wintersmith"
      end

      it "lets you save new contents" do
        @mirror.commit("hiver")
        @mirror.read.should == "hiver"
      end
      
      it "preserves line endings" do
        write_testfile_contents("a\nb")
        
        @mirror.read.should == "a\nb"
        write_testfile_contents("a\r\nb")
        @mirror.read.should == "a\r\nb"
      end
      
      describe "that you have read" do
        before do
          @mirror.read
        end
        
        it "tells you it has not changed" do
          @mirror.changed?.should be_false
        end
        
        describe "and since committed" do
          before do
            @mirror.commit("hiver")
          end
          
          it "tells you it has not changed" do
            @mirror.changed?.should be_false
          end
        end
        
        describe "and has since changed on disk" do
          before do
            sleep 2
            write_testfile_contents("the queen")
          end
          
          it "tells you it has changed" do
            @mirror.changed?.should be_true
          end
          
          describe "and since committed" do
            before do
              @mirror.commit("the queen")
            end
            
            it "tells you it has not changed" do
              @mirror.changed?.should be_false
            end
          end
        end
      end
    end
    
    describe "for a nonexistent file" do
      it "tells you if a file doesn't exist" do
        FileMirror.new("nontestfile").exists?.should be_false
      end
      
      it "returns an empty string for the contents" do
        FileMirror.new("nontestfile").read.should == ""
      end
    end
  end
end