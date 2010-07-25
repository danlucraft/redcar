class Redcar::REPL
  describe ClojureMirror do
    before(:all) do
      @mirror = ClojureMirror.new
      @changed_event = false
      @mirror.add_listener(:change) { @changed_event = true }
    end
    
    def commit_test_text
      text = (<<-CLOJURE).chomp
# Clojure REPL

user=> (println [1 2 3])
CLOJURE
      @mirror.commit(text)
    end
    
    def result_test_text
      (<<-CLOJURE).chomp
# Clojure REPL

user=> (println [1 2 3])
[1 2 3]

nil
user=> 
CLOJURE
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
          
  end
end