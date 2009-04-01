Feature: Multiple panes
  As a user
  I want to split up my workspace into multiple areas
  In order to have all aspects of my project visible at a glance

  Scenario: Single pane
    Then there should be 1 pane

  Scenario: Split Horizontal
    When I press "Ctrl+2"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::VPaned
          Gtk::Notebook
          Gtk::Notebook
      """

  Scenario: Split Vertical
    When I press "Ctrl+3"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::HPaned
          Gtk::Notebook
          Gtk::Notebook
      """

  Scenario: Split Horizontal then Vertical
    When I press "Ctrl+2"
    And I press "Ctrl+3"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::VPaned
          Gtk::HPaned
            Gtk::Notebook
            Gtk::Notebook
          Gtk::Notebook
      """

  Scenario: Split Horizontal then Unify
    When I press "Ctrl+2"
    And I press "Ctrl+1"
    Then there should be 1 pane

  Scenario: Split Vertical then Unify
    When I press "Ctrl+3"
    And I press "Ctrl+1"
    Then there should be 1 pane
