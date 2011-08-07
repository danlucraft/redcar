Feature: Navigation History

Background:
  Given I will choose "plugins/application/features/some_project" from the "open_directory" dialog
  When I open a directory
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And I move to line 2
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  And I select the outline view
  Then the cursor should be on line 0
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  When I set the outline filter to "delim"
  And I wait 2 seconds
  And I select the outline view
  Then the cursor should be on line 179
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And I move to line 5
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  And I select the outline view
  Then the cursor should be on line 0

Scenario: Backward/forward history
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 5
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And the cursor should be on line 179
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And the cursor should be on line 0
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And the cursor should be on line 2
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And the cursor should be on line 0
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And the cursor should be on line 179
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 0

Scenario: Change middle history
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 0
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 5
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  When I set the outline filter to "ano"
  And I wait 2 seconds
  And I select the outline view
  Then the cursor should be on line 7
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And the cursor should be on line 7