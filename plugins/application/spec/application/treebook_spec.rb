require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Treebook do

  describe "a new treebook" do
    before do
      @treebook = Redcar::Treebook.new
    end

    it "has no trees" do
      @treebook.trees.length.should == 0
    end

    it "accepts a tree and notifies listeners" do
      tree = MockTree.new("mock tree")
      tree_added = false
      @treebook.add_listener(:tree_added) do |tree|
        tree_added = tree
      end

      @treebook.add_tree(tree)

      tree_added.should == tree
      @treebook.trees.should == [tree]
    end
  end
end