# Feature: Moving and renaming files

#   Background:
#     Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
#     When I open a directory
#
#   Scenario: Renaming a file which is currently open
#     Given I will choose "plugins/project/spec/fixtures/myproject/test1/a.txt" from the "open_file" dialog
#     When I open a file
#     Given I will choose "summer.txt" as the rename text
#     When I rename the "a.txt" node in the tree
#     Then my active tab should be "summer.txt"
#
#   Scenario: Bulk renaming files which are currently open
#     Given I will choose "plugins/project/spec/fixtures/myproject/test1/a.txt" from the "open_file" dialog
#     When I open a file
#     Given I will choose "plugins/project/spec/fixtures/myproject/test1/b.txt" from the "open_file" dialog
#     When I open a file
#     And I bulk rename the "a.txt,b.txt" nodes in the tree replacing "" with "Test"
#     Then my active tab should be "Testb.txt"
#     When I close the focussed tab
#     Then my active tab should be "Testa.txt"

# There isn't a good way to simulate file rename text entry at this moment

