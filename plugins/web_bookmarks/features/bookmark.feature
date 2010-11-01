Feature: Showing and opening bookmarks in a tree

  Background:
    When I will choose "plugins/web_bookmarks/features/fixtures" from the "open_directory" dialog
    And I open a directory
    
  Scenario: Show grouped bookmarks from .redcar/web_bookmarks.json in the project
    When I open the web bookmarks tree
    Then I should see "Online" in the tree
    And I should see "Sample" in the tree
    
  Scenario: Show individual bookmarks in groups
    When I open the web bookmarks tree
    And I expand the tree row "Online"
    Then I should see "Google" in the tree
    And I should see "Github" in the tree
    
  Scenario: Opening a bookmark from the tree
    When I open the web bookmarks tree
    And I activate the "Sample" node in the tree
    Then my active tab should be "Sample"
    And the HTML tab should say "Hello!!"