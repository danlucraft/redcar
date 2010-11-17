Feature: Navigating web content in HtmlTabs using the browser bar

  Background:
    When I will choose "plugins/html_view/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I open the browser bar
    And I type "sample.html" into the "New URL:" field in the speedbar
    And I press "Go!" in the speedbar

  Scenario: Refresh a tab
    Given I will choose "plugins/html_view/features/fixtures/sample.html" from the "open_file" dialog
    When I open a file
    And I replace the contents with "<html>I see you!</html>"
    And I save the tab
    And I close the focussed tab
    And I open the browser bar
    And I press "Refresh" in the speedbar
    Then the HTML tab should say "I see you!"

  Scenario: Go to a new URL in a HtmlTab
    When I type "other.html" into the "New URL:" field in the speedbar
    And I press "Go!" in the speedbar
    Then the HTML tab should say "Is today Tuesday?"

  Scenario: Move back and forward in the browser history
    When I type "other.html" into the "New URL:" field in the speedbar
    And I press "Go!" in the speedbar
    And I press "<" in the speedbar
    Then the HTML tab should say "Hello!!"
    When I press ">" in the speedbar
    Then the HTML tab should say "Is today Tuesday?"

  Scenario: View page source from the browser bar
    When I press "Source" in the speedbar
    Then I should see "<html><b>Hello!!</b></html>" in the edit tab

  Scenario: Add a new bookmark to a project
    When I type "other.html" into the "New URL:" field in the speedbar
    Given I would type "Other" in an input box
    And I would type "" in an input box
    When I press "+" in the speedbar
    And I open the web bookmarks tree
    Then I should see "Other" in the tree

  Scenario: When a HTML tab loses focus, the browser bar is hidden
    When I open a new edit tab
    Then there should not be an open speedbar
