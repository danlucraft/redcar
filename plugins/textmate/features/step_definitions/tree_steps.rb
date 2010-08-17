
When /^I click Show Bundles in Tree$/ do
    Redcar::Textmate::ShowSnippetTree.new.run
end

Then /^I should see a tree mirror titled "([^"]*)"$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t| 
    t.tree_mirror.title  == "Bundles"
  end
end

Then /^I should see bundle names, like "([^"]*)" in the tree$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t| 
    t.tree_mirror.top.detect do |child|
      Redcar::Textmate.all_bundles.detect do |bundle|
        bundle.name == child.text
      end
    end
  end
end

When /^I open "([^"]*)" in the tree$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t| 
    t.tree_mirror.title == arg1 and t.tree_mirror.top
  end
end

Then /^I should see snippet groups "([^"]*)" listed$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t|     
    t.tree_mirror.top.detect do |child|
      child.is_a?(Redcar::Textmate::SnippetGroup) and child.text == arg1        
    end
  end
end

Then /^I should see snippets "([^"]*)" listed$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t| 
    t.tree_mirror.top.detect do |child|
      child.is_a?(Redcar::Textmate::SnippetNode) and child.leaf? and child.text == arg1
    end
  end
end

 When /^I add a bundle$/ do
  FileUtils.cp_r(test_bundle, tmp_bundle_path)
 end

Then /^I should see "([^"]*)" in the tree$/ do |arg1|
  Redcar.app.focussed_window.treebook.trees.detect do |t| 
    t.tree_mirror.top.detect do |child|
      Redcar::Textmate.all_bundles.detect do |bundle|
        bundle.name == "test_bundle"
      end
    end
  end
end