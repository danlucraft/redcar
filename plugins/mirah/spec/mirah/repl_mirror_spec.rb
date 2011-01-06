require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Redcar::Mirah
  describe ReplMirror do
    before do
      @mirror = ReplMirror.new
      @changed_event = false
      @mirror.add_listener(:change) { @changed_event = true }
    end

    def commit_test_text1
      text = <<-MIRAH
# Mirah REPL
# type 'help' for help

>> $internal_repl_test = 707
MIRAH
      @mirror.commit(text.chomp)
    end

    def result_test_text1
      (<<-MIRAH).chomp
# Mirah REPL
# type 'help' for help

>> $internal_repl_test = 707
=> 707
>> 
MIRAH
    end

    def commit_test_text2
      text = <<-MIRAH
# Mirah REPL
# type 'help' for help

>> $internal_repl_test = 707
=> 707
>> $internal_repl_test = 909
MIRAH
      @mirror.commit(text.chomp)
      text.chomp
    end

    def result_test_text2
      (<<-MIRAH).chomp
# Mirah REPL
# type 'help' for help

>> $internal_repl_test = 707
=> 707
>> $internal_repl_test = 909
=> 909
>> 
MIRAH
    end


    def commit_no_input
      text = <<-MIRAH
# Mirah REPL
# type 'help' for help

>> 
MIRAH
      @mirror.commit(text)
    end

    def prompt
      "# Mirah REPL\n\n"
    end

    describe "with no history" do
      it "should exist" do
        @mirror.should be_exist
      end

      it "should have a message and a prompt" do
        @mirror.read.should == (<<-MIRAH).chomp
# Mirah REPL
# type 'help' for help

>> 
MIRAH
      end

      it "should have a title" do
        @mirror.title.should == "Mirah REPL"
      end

      it "should not be changed" do
        @mirror.should_not be_changed
      end

      describe "when executing" do
        it "should execute committed text" do
          commit_test_text1
          $internal_repl_test.should == 707
        end

        it "should allow committing nothing as the first command" do
          commit_no_input
          @mirror.read.should == "# Mirah REPL\n# type 'help' for help\n\n>> \n=> nil\n>> "
        end

        it "should allow committing nothing as an xth command" do
          committed = commit_test_text2
          @mirror.commit committed + "\n>> "
          @mirror.read.should == "# Mirah REPL\n# type 'help' for help\n\n>> $internal_repl_test = 909\n=> 909\n>> \n=> nil\n>> "
        end

        it "should emit changed event when text is executed" do
          commit_test_text1
          @changed_event.should be_true
        end

        it "should now have the command and the result at the end" do
          commit_test_text1
          @mirror.read.should == result_test_text1
        end

        it "should display errors" do
          @mirror.commit(prompt + ">> nil.foo")
          text = <<-MIRAH
# Mirah REPL
# type 'help' for help

>> nil.foo
x> NoMethodError: undefined method `foo' for nil:NilClass
        (repl):1
MIRAH
          @mirror.read.include?(text).should be_true
        end
      end
    end

    describe "with a history" do
      before do
        commit_test_text1
      end

      it "should not have changed" do
        @mirror.changed?.should be_false
      end

      it "should display the history and prompt correctly" do
        @mirror.read.should == result_test_text1
      end

      describe "when executing" do
        it "should execute committed text" do
          commit_test_text2
          $internal_repl_test.should == 909
        end

        it "should show the correct history" do
          commit_test_text2
          @mirror.read.should == result_test_text2
        end

        it "should allow the history to be cleared" do
          @mirror.clear_history
          @mirror.read.should == ">> "
        end

      end
    end

# somehow ...
#     describe "when executing" do
#       it "should persist local variables" do
#         sent = prompt + ">> a = 13"
#         @mirror.commit(sent)
#         @mirror.commit(sent + "\n>> a")
#         @mirror.read.should == (<<-MIRAH).chomp
# # Mirah REPL
# # type 'help' for help
# 
# >> a = 13
# => 13
# >> a
# => 13
# >> 
# MIRAH
#       end
#    end
  end
end