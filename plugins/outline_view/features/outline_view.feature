Feature: Outline View

Background:
  Given I will choose "plugins/outline_view/spec/fixtures/some_project" from the "open_directory" dialog
  When I open a directory

Scenario: Outline View without anything to see
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/nothing_to_see.rb"
  And I open an outline view
  Then there should be an outline view open
  And the outline view should have no entries

Scenario: Outline View with something small
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/one_lonely_class.rb"
  And I open an outline view
  Then there should be an outline view open
  And the outline view should have 1 entry
  When I select the outline view
  Then the selected text should be "class IAmAllAlone"
  
Scenario: Something fancier
  Given I have opened "plugins/outline_view/spec/fixtures/some_project/something_fancy.rb"
  And I open an outline view
  Then there should be an outline view open
  And the outline view should have 86 entries
  When I set the outline filter to "selected"
  And I wait 2 seconds
  Then the outline view should have 2 entries
  And I select the outline view
  Then the selected text should be "    def selection_range_changed"
  