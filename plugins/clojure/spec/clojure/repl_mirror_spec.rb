require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Redcar::Clojure
  describe ReplMirror do
    before(:all) do
      @mirror = ReplMirror.new
      @changed_event = false
      @mirror.add_listener(:change) { @changed_event = true }
    end

    def wait_for_prompt
      while @mirror.read.nil? || @mirror.read[-3,3] != "=> "
      end
    end

    describe "before executing" do
      it "should exist" do
        @mirror.should be_exist
      end

      it "should have a title" do
        @mirror.title.should == "Clojure REPL"
      end

      it "should not be changed" do
        @mirror.should_not be_changed
      end
    end

    describe "after executing" do
      it "should exist" do
        @mirror.should be_exist
      end

      it "should have a title" do
        @mirror.title.should == "Clojure REPL"
      end

      it "should not be changed" do
        @mirror.should_not be_changed
      end

      it "should have a prompt" do
        wait_for_prompt
        @mirror.read.should == (<<-CLOJURE).chomp
# Clojure REPL
# type 'help' for help

user=> 
CLOJURE
      end
    end
  end
end