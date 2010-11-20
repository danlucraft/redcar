Feature: Outline View

Background:
  Given I will choose "plugins/outline_view/spec/fixtures/some_project" from the "open_directory" dialog
  When I open a directory

Scenario: Outline View without anything to see
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/nothing_to_see.rb"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have no entries

Scenario: Outline View with something small
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/one_lonely_class.rb"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have 1 entry
  And I should see "IAmAllAlone" at 0 with the "class" icon in the outline view
  When I select the outline view
  Then the selected text should be "class IAmAllAlone"

Scenario: Ruby methods with trailing space
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/trailing_space.rb"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have 2 entries
  And I should see "trailing_space" at 1 with the "method" icon in the outline view

Scenario: Something fancier
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have 88 entries
  And I should see "Redcar" at 0 with the "class" icon in the outline view
  When I set the outline filter to "delim"
  And I wait 2 seconds
  Then the outline view should have 2 entries
  And I should see "delim" at 1 with the "alias" icon in the outline view
  And I should see "line_delimiter" at 0 with the "method" icon in the outline view
  When I set the outline filter to "selected"
  And I wait 2 seconds
  Then the outline view should have 2 entries
  And I should see "selection_range_changed" at 0 with the "method" icon in the outline view
  And I should see "selected_text" at 1 with the "method" icon in the outline view
  And I select the outline view
  Then the selected text should be "    def selection_range_changed(start_offset, end_offset)\n"

Scenario: Matching kinda similar names
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/similar_names.rb"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have 6 entries
  And I should see "SimilarNames" at 0 with the "class" icon in the outline view
  And I should see "file" at 1 with the "method" icon in the outline view
  And I should see "file_name" at 2 with the "method" icon in the outline view
  And I should see "file_type" at 3 with the "method" icon in the outline view
  And I should see "file_handle" at 4 with the "method" icon in the outline view
  And I should see "file" at 5 with the "method" icon in the outline view
  When I set the outline filter to "file"
  And I wait 2 seconds
  Then the outline view should have 5 entries

Scenario: Simple Javascript
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/javascript.js"
  And I run the command Redcar::OutlineView::OpenOutlineViewCommand
  Then there should be an outline view open
  And the outline view should have 3 entries
  And I should see "SomeConstructor" at 0 with the "class" icon in the outline view
  When I set the outline filter to "some"
  And I wait 2 seconds
  Then the outline view should have 2 entries
  And I should see "someMethod" at 1 with the "method" icon in the outline view
  And I should see "SomeConstructor" at 0 with the "class" icon in the outline view
  When I set the outline filter to "another"
  And I wait 2 seconds
  Then the outline view should have 1 entry
  And I should see "anotherMethod" at 0 with the "method" icon in the outline view
  And I select the outline view
  Then the selected text should be "function anotherMethod(a,b,c)"
