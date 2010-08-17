
When /^I click Show Bundles in Tree$/ do
    Redcar::Textmate::ShowSnippetTree.new.run
end

Then /^I should see a tree mirror titled "([^"]*)"$/ do |arg1|
  val = Redcar.app.focussed_window.treebook.trees.detect do |t|
    t.tree_mirror.title == arg1
  end
end

When /^I open "([^"]*)" in the tree$/ do |arg1|
  val = Redcar.app.focussed_window.treebook.trees.detect do |t|
    t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror) and t.tree_mirror.top.detect do |child|
      if child.text == arg1
        @top = child.children
        true
      end
    end
  end
  val.should be_true
end

Then /^I should see snippet groups "([^"]*)" listed$/ do |arg1|
  val = @top.detect do |child|
    child.is_a?(Redcar::Textmate::SnippetGroup) and child.text == arg1
  end
  val.should be_true
end

Then /^I should see snippets "([^"]*)" listed$/ do |arg1|
  val = @top.detect do |child|
    child.is_a?(Redcar::Textmate::SnippetNode) and child.text.match(/^#{arg1}/)
  end
  val.should be_true
end

 When /^I add a bundle$/ do
  FileUtils.mkdir tmp_bundle_path_1
  FileUtils.cp_r(test_bundle, bundle_path)
 end

Then /^I should (see|not see) "([^"]*)" in the tree$/ do |see,arg1|
  val = Redcar.app.focussed_window.treebook.trees.detect do |t|
    t.tree_mirror.top.detect do |child|
      Redcar::Textmate.all_bundles.detect do |bundle|
        bundle.name == arg1
      end
    end
  end
  case see
  when "see"
  val.should be_true
  when "not see"
    val.should be_nil
  end
end