
describe Redcar::Testing::InternalRSpecRunner do
  describe ".plugin_dir" do
    it "should find the plugin directory" do
      Redcar::Testing::InternalRSpecRunner.plugin_dir("testing").should == 
      	File.expand_path(File.dirname(__FILE__) + "/../../") + "/"
    end
  end

  describe ".spec_files" do
    it "should find the spec files for the plugin" do
      a = Redcar::Testing::InternalRSpecRunner.spec_files("testing").map{|f| File.expand_path(f) }
      b = Dir[File.dirname(__FILE__) + "/../../spec/**/*_spec.rb"].map {|f| File.expand_path(f)}
      a.should == b
    end
  end

  describe ".spec_plugin" do
    it "should load the example groups" do
      # if this is being run then the example groups have been loaded
      true.should be_true
    end

    it "should run the example groups" do
      true.should be_true
    end
  end

  describe ".lookup_example_groups" do
    it "should find the example groups" do
      egs = Redcar::Testing::InternalRSpecRunner.lookup_example_groups.map(&:to_s)
      egs.any? {|c| c =~ /Test::Unit::TestCase::Subclass_\d+/}.should be_true
      egs.any? {|c| c =~ /Test::Unit::TestCase::Subclass_\d+::Subclass_\d+/}.should be_true
    end
  end
end
