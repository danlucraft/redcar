Feature: Project-wide Outline View

Background:
  Given I will choose "plugins/outline_view/spec/fixtures/some_project" from the "open_directory" dialog
  When I open a directory

Scenario: Outline View shows all available declarations
  When I run the command Redcar::OutlineView::OpenProjectOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have some entries
  And I should see "IAmAllAlone" at 0 with the "class" icon in the outline view
  And I should see "trailing_space" at 1 with the "method" icon in the outline view

Scenario: Narrow results using the filter
  When I run the command Redcar::OutlineView::OpenProjectOutlineViewCommand
  Then there should be an outline view open
  When I set the outline filter to "selected"
  And I wait 2 seconds
  Then the outline view should have 2 entries
  And I should see "selection_range_changed" at 0 with the "method" icon in the outline view
  And I should see "selected_text" at 1 with the "method" icon in the outline view
  And I select the outline view
  Then the selected text should be "    def selection_range_changed(start_offset, end_offset)\n"
