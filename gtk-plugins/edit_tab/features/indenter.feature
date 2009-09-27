Feature: Automatically indent text

  Scenario: Indent next line (Ruby)
    Given there is an EditTab open with syntax "Ruby"
    When I type "def foo"
    And I press "Return"
    Then I should see "foo\n  <c>" in the EditTab

  Scenario: Unindent line (Ruby)
    Given there is an EditTab open with syntax "Ruby"
    When I type "def foo"
    And I press "Return"
    And I type "end"
    Then I should see "foo\nend<c>" in the EditTab
    
  Scenario: Indent next line but one (Ruby)
    Given there is an EditTab open with syntax "Ruby"
    When I type "def foo"
    And I press "Return" then "Return"
    Then I should see "foo\n  \n  <c>" in the EditTab

  # why does this not work??
  # Scenario: Automatic indent next line (C)
  #   Given there is an EditTab open with syntax "C"
  #   When I type "if (i == 0)"
  #   And I press "Return"
  #   Then I should see "0)\n  <c>" in the EditTab

  # TODO
  # Scenario: Automatic indent next line only (C)
  #   Given there is an EditTab open with syntax "C"
  #   When I type "if (i == 0)"
  #   And I press "Return"
  #   And I type "puts"
  #   And I press "Return"
  #   Then I should see "0)\n  puts\n<c>" in the EditTab

  # why does this not work??
  # Scenario: Requested indent next line only (C)
  #   Given there is an EditTab open with syntax "C"
  #   When I type "if (i == 0)"
  #   And I press "Return"
  #   And I type "puts"
  #   And I press "Return" then "Super+Alt+["
  #   Then I should see "0)\n  puts\n<c>" in the EditTab

  # TODO
  # Scenario: Automatic unindented line (C)
  #   Given there is an EditTab open with syntax "C"
  #   When I type "if (i == 0)"
  #   And I press "Return"
  #   And I type "#define"
  #   Then I should see "0)\n#define<c>" in the EditTab    

  Scenario: Requested unindented line (C)
    Given there is an EditTab open with syntax "C"
    When I type "if (i == 0)"
    And I press "Return"
    And I type "#define"
    And I press "Super+Alt+["
    Then I should see "0)\n#define<c>" in the EditTab    

  Scenario: Increase and decrease indent in one line (Ruby)
    Given there is an EditTab open with syntax "Ruby"
    When I type "def foo; end"
    And I press "Return"
    Then I should see "end\n<c>" in the EditTab

  Scenario: Increase indent twice in one line (Ruby)
    Given there is an EditTab open with syntax "Ruby"
    When I type "def foo; if a"
    And I press "Return"
    Then I should see "if a\n  <c>" in the EditTab

  Scenario: Indent pasted text
    Given there is an EditTab open with syntax "Ruby"
    When I type "def f\nend\np :hi\n"
    And I press "Up" then "Ctrl+Shift+L"
    And I press "Ctrl+X" then "Up"
    And I press "Ctrl+V"
    Then I should see "def f\n  p :hi\n<c>end" in the EditTab

  Scenario: Indent multiple lines of pasted text
    Given there is an EditTab open with syntax "Ruby"
    When I type "def f\nend\nif a\np :hi\nend\n"
    And I press "Shift+Up" then "Shift+Up"
    And I press "Shift+Up" then "Ctrl+X"
    And I press "Up" then "Ctrl+V"
    Then I should see "def f\n  if a\n    p :hi\n  end\n<c>end" in the EditTab






