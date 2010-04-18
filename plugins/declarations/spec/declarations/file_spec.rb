
require File.join(File.dirname(__FILE__), "..", "spec_helper")

module Redcar
  describe Declarations::File do
    before do
      @tags_file = File.join(File.dirname(__FILE__), "..", "tags")
    end
    
    after do
      FileUtils.rm_f(@tags_file)
    end
    
    describe "dump and load from file" do
      describe "with no existing tags file" do
        before do
          @file = Declarations::File.new(@tags_file)
        end
        
        it "should have no tags" do
          @file.tags.should be_empty
        end
        
        it "should accept new tags" do
          @file.add_tags([%w"Abc /foo class:Abc"])
          @file.tags.length.should == 1
        end
        
        describe "with tags added" do
          before do
            @file.add_tags([%w"Abc /foo class:Abc"])
          end
          
          it "should dump a tags file" do
            @file.dump
            File.exist?(@tags_file).should be_true
          end
        end
      end
      
      describe "with existing tags file" do
        before do
          file = Declarations::File.new(@tags_file)
          file.add_tags([%w"Abc /foo class:Abc"])
          file.dump
          @file = Declarations::File.new(@tags_file)
        end
        
        it "should load up the tags" do
          @file.tags.should == [%w"Abc /foo class:Abc"]
        end
      end
    end
    
    describe "remove tags for file" do
      before do
        file = Declarations::File.new(@tags_file)
        file.add_tags([
                        %w"Abc /foo class:Abc",
                        %w"Def /bar class:Def",
                        %w"Ghi /baz class:Ghi",
                      ])
        file.dump
        @file = Declarations::File.new(@tags_file)
      end
      
      it "should remove tags for a file" do
        @file.remove_tags_for_paths(["/bar", "/baz"])
        @file.tags.length.should == 1
      end
    end
  end
end