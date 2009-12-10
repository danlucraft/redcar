require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Redcar::Project
  describe DirMirror do
    def write_dir_contents(dirname, files)
      FileUtils.mkdir_p(dirname)
      files.each do |filename, contents|
        File.open(dirname + "/" + filename, "w") {|f| f.print contents}
      end
    end
    
    before do
      @dirname = "project_spec_testdir"
      @files = {"Carnegie" => "steel", 
                "Rockefeller" => "oil"}
      write_dir_contents(@dirname, @files)
      @dirname2 = "project_spec_testdir/subdir"
      @files2 = {"Ford" => "cars"}
      write_dir_contents(@dirname2, @files2)
      @mirror = DirMirror.new(File.expand_path(@dirname))
    end

    describe "for a directory" do
    
      it "tells you the directory exists" do
        @mirror.exists?.should be_true
      end
    end
    
    after do
      FileUtils.rm_r(@dirname)
    end
  end
end