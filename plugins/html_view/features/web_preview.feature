Feature: Previewing how a file will appear in a browser

  Scenario: Previewing an untitled tab
    When I open a new edit tab
    And I replace the contents with "<html>test 1-2-3</html>"
    And I open a web preview
    Then my active tab should be "Preview"
    And the HTML tab should say "test 1-2-3"

  Scenario: Previewing a saved file
    Given I will choose "plugins/html_view/features/fixtures/sample.html" from the "open_file" dialog
    When I open a file
    And I replace the contents with "<html>test 1-2-3</html>"
    And I open a web preview
    Then my active tab should be "Preview: sample.html"
    And the HTML tab should say "Hello!!"
    When I close the focussed tab
    And I save the tab
    And I open a web preview
    Then my active tab should be "Preview: sample.html"
    And the HTML tab should say "test 1-2-3"
