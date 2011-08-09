Feature: Navigation History

Background:
  Given I have opened "plugins/application/spec/application/navigation_history_spec.rb"
  And I move to line 2
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  And I select the outline view
  Then the cursor should be on line 1
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  When I set the outline filter to "con"
  And I wait 2 seconds
  And I select the outline view
  Then the cursor should be on line 14
  Given I have opened "plugins/application/lib/application/navigation_history.rb"
  And I move to line 5
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  And I select the outline view
  Then the cursor should be on line 0

Scenario: Backward/forward history
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 5
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/spec/application/navigation_history_spec.rb"
  And the cursor should be on line 14
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/spec/application/navigation_history_spec.rb"
  And the cursor should be on line 1
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/spec/application/navigation_history_spec.rb"
  And the cursor should be on line 2
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/spec/application/navigation_history_spec.rb"
  And the cursor should be on line 1
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/spec/application/navigation_history_spec.rb"
  And the cursor should be on line 14
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 0

Scenario: Change middle history
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 0
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 5
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  When I set the outline filter to "can"
  And I wait 2 seconds
  And I select the outline view
  Then the cursor should be on line 21
  When I run the command Redcar::Top::BackwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 5
  When I run the command Redcar::Top::ForwardNavigationCommand
  Then the focussed document path is "plugins/application/lib/application/navigation_history.rb"
  And the cursor should be on line 21