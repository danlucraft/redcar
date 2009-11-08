require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Redcar::REPL
  describe InternalMirror do
    before do
      @mirror = InternalMirror.new
    end
    
    describe "with no history" do
      it "should exist" do
        @mirror.should be_exist
      end
      
      it "should have a message" do
        @mirror.read.include?("REPL").should be_true
      end
      
      it "should have a title" do
        @mirror.title.should == "(internal)"
      end
      
      it "should have a prompt" do
        @mirror.read.should match(/>> $/)
      end
      
#       it "should execute committed text" do
#         text = <<-RUBY
# *** Redcar REPL
# 
# >> 
#         RUBY
#         @mirror.commit
#       end
    end
  end
end