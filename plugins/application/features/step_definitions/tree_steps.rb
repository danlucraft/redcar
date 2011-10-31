
When /^I expand the tree row "([^\"]*)"$/ do |row|
  Swt.sync_exec do
    item = visible_tree_items(top_tree).detect {|item| item.getText == row }
    viewer = focussed_tree.controller.viewer
    node = viewer.getViewerRowFromItem(item).getElement
    viewer.expandToLevel(node, 1)
  end
end

When /^I toggle tree visibility$/ do
  Swt.sync_exec do
    Redcar::Application::ToggleTreesCommand.new.run
  end
end

When "I close the tree" do
  Swt.sync_exec do
    Redcar::Application::CloseTreeCommand.new.run
  end
end

When /^I switch (up|down) a tree$/ do |type|
  Swt.sync_exec do
    case type
    when "down"
      Redcar::Application::SwitchTreeDownCommand.new.run
    when "up"
      Redcar::Application::SwitchTreeUpCommand.new.run
    end
  end
end

When "I click the close button" do
  Swt.sync_exec do
    vtabitem = focussed_window.treebook.controller.tab_folder.selection
    swtlabel = swt_label_for_item(vtabitem)
  
    # Make sure the close icon is showing
    FakeEvent.new(Swt::SWT::MouseEnter, swtlabel)
  
    # Fire the click event
    FakeEvent.new(Swt::SWT::MouseUp, swtlabel,
      :x => Swt::Widgets::VTabLabel::ICON_PADDING + 1,
      :y => Swt::Widgets::VTabLabel::ICON_PADDING + 1)
  end
end

When /^I (?:(left|right)-)?click the (project|directory|"[^\"]*") tree tab$/ do |button, target|
  Swt.sync_exec do
    if target =~ /(project|directory)/
      path  = Redcar::Project::Manager.in_window(Redcar.app.focussed_window).path
      target = File.basename(path) + "/"
    end
    target.gsub!('"', '')
    vtabitem = focussed_window.treebook.controller.tab_folder.get_item(target)
    swtlabel = swt_label_for_item(vtabitem)
  
    button = (button == "right" ? 2 : 1)
    FakeEvent.new(Swt::SWT::MouseEnter, swtlabel)
    FakeEvent.new(Swt::SWT::MouseUp, swtlabel, :x => 1, :y => 1, :button => button)
  end
end

Then /^I should (not )?see "([^\"]*)" in the tree$/ do |negate, rows|
  Swt.sync_exec do
    item_names = visible_tree_items(top_tree).map(&:get_text)
    rows.split(',').map(&:strip).each do |row|
      if negate
        item_names.should_not include row
      else
        item_names.should include row
      end
    end
  end
end

Then /^there should (not )?be a tree titled "([^\"]*)"$/ do |negate,title|
  Swt.sync_exec do
    if negate
      tree_with_title(title).should == nil
    else
      tree_with_title(title).should_not == nil
    end
  end
end

Then /^the focussed tree should be titled "([^\"]*)"$/ do |title|
  Swt.sync_exec do
    focussed_tree.title.should == title
  end
end

Then /^the tree width should be (the default|\d+ pixels|the minimum size)$/ do |w|
  Swt.sync_exec do
    width = focussed_treebook_width
    if w == "the default"
      unless width == default_treebook_width
        raise "The tree width was #{width}, expected #{default_treebook_width}"
      end
    elsif w == "the minimum size"
      width.should == Redcar::ApplicationSWT::Window::MINIMUM_TREEBOOK_WIDTH
    else
      width.should == w.split(" ")[0].to_i
    end
  end
end

When /^I activate the "([^"]*)" node in the tree$/ do |node_text|
  Swt.sync_exec do
    controller = focussed_tree.tree_controller
    model      = focussed_tree.controller.model
    mirror     = focussed_tree.tree_mirror
    node       = find_node_with_text(mirror.top, node_text)
  
    node.should_not be_nil
  
    controller.activated(model, node)
  end
end

When /^I rename the "([^"]*)" node in the tree$/ do |node_text|
  Swt.sync_exec do
    controller = focussed_tree.tree_controller
    mirror     = focussed_tree.tree_mirror
    node       = find_node_with_text(mirror.top, node_text)
  
    node.should_not be_nil
    controller.single_rename(focussed_tree, node)
  end
end