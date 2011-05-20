@project-fixtures
Feature: Find file

  Background:
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory

  Scenario: No files initially and with nothing typed
    When I open the find file dialog
    Then there should be a filter dialog open
    And the filter dialog should have no entries

  Scenario: No matching files
    When I open the find file dialog
    And I set the filter to "xxx"
    And I wait "0.4" seconds
    Then the filter dialog should have 0 entries

  Scenario: No matching files when typing a directory name only
    When I open the find file dialog
    And I set the filter to "vendor"
    And I wait "0.4" seconds
    Then the filter dialog should have 0 entries

  Scenario: One matching file
    When I open the find file dialog
    And I set the filter to "foo_spec"
    And I wait "0.4" seconds
    Then the filter dialog should have 1 entry
    And I should see "foo_spec.rb (myproject/spec)" at 0 the filter dialog

  Scenario: One matching file - spaces ignored
    When I open the find file dialog
    And I set the filter to "foo spec"
    And I wait "0.4" seconds
    Then the filter dialog should have 1 entry
    And I should see "foo_spec.rb (myproject/spec)" at 0 the filter dialog

  Scenario: One matching file when specifying a symlinked directory
    When I open the find file dialog
    And I set the filter to "lib_sym/foo"
    And I wait "0.4" seconds
    Then the filter dialog should have 1 entry
    And I should see "foo_lib.rb (myproject/lib_symlink)" at 0 the filter dialog

  Scenario: Two matching files, plus one in symlink
    When I open the find file dialog
    And I set the filter to "foo"
    And I wait "1.4" seconds
    Then the filter dialog should have 3 entries
    And I should see "foo_lib.rb (myproject/lib)" at 0 the filter dialog
    And I should see "foo_lib.rb (myproject/lib_symlink)" at 1 the filter dialog
    And I should see "foo_spec.rb (myproject/spec)" at 2 the filter dialog

  Scenario: Two matching files, plus one in symlink - spaces ignored
    When I open the find file dialog
    And I set the filter to "foo rb"
    And I wait "0.4" seconds
    Then the filter dialog should have 3 entries
    And I should see "foo_lib.rb (myproject/lib)" at 0 the filter dialog
    And I should see "foo_lib.rb (myproject/lib_symlink)" at 1 the filter dialog
    And I should see "foo_spec.rb (myproject/spec)" at 2 the filter dialog

 Scenario: Three matching files in similar directories
    When I open the find file dialog
    And I set the filter to "ven/bar"
    And I wait "0.4" seconds
    Then the filter dialog should have 2 entries
    And I should see "bar.rb (myproject/vendor)" at 0 the filter dialog
    And I should see "bar.rb (vendor/plugins)" at 1 the filter dialog

 Scenario: Two matching files in similar nested directories
    When I open the find file dialog
    And I set the filter to "v/p/bar"
    And I wait "0.4" seconds
    Then the filter dialog should have 1 entry
    And I should see "bar.rb (vendor/plugins)" at 0 the filter dialog

  Scenario: One matching file with arbitrary letters
    When I open the find file dialog
    And I set the filter to "fsc"
    And I wait "0.4" seconds
    Then the filter dialog should have 1 entry
    And I should see "foo_spec.rb (myproject/spec)" at 0 the filter dialog

  Scenario: Open a file
    When I open the find file dialog
    And I set the filter to "fsc"
    And I wait "0.4" seconds
    And I select in the filter dialog
    Then there should be no filter dialog open
    And I should see "foo spec" in the edit tab

  Scenario: Open a file then see the file in the initial list
    When I open the find file dialog
    And I set the filter to "fsc"
    And I wait "0.4" seconds
    And I select in the filter dialog
    And I open the find file dialog
    Then the filter dialog should have 1 entry
    And I should see "foo_spec.rb (myproject/spec)" at 0 the filter dialog

  Scenario: Open two files then see the files in the initial list
    When I have opened "plugins/project/spec/fixtures/myproject/spec/foo_spec.rb"
    And I have opened "plugins/project/spec/fixtures/myproject/lib/foo_lib.rb"
    And I open the find file dialog
    Then the filter dialog should have 2 entries
    And I should see "foo_spec.rb (myproject/spec)" at 0 the filter dialog
    And I should see "foo_lib.rb (myproject/lib)" at 1 the filter dialog

  Scenario: Open three files then see the files in the initial list
    When I have opened "plugins/project/spec/fixtures/myproject/spec/foo_spec.rb"
    And I have opened "plugins/project/spec/fixtures/myproject/lib/foo_lib.rb"
    And I have opened "plugins/project/spec/fixtures/myproject/README"
    And I open the find file dialog
    Then the filter dialog should have 3 entries
    And I should see "foo_lib.rb (myproject/lib)" at 0 the filter dialog
    And I should see "foo_spec.rb (myproject/spec)" at 1 the filter dialog
    And I should see "README (fixtures/myproject)" at 2 the filter dialog