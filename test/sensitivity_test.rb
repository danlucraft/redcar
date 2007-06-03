

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestSensitivity < Test::Unit::TestCase
  def setup
    startup
  end
  def teardown
    shutdown
  end
  
  def test_sensitivity_of_widget
    widget = Gtk::Button.new
    widget.show
    widget.sensitive = true
    Redcar::Sensitivity.add(:foo, :hooks => [:foo]) { @on }
    widget.sensitize_to :foo
    assert widget.sensitive?
    @on = false
    Redcar.event :foo
    assert !widget.sensitive?
    @on = true
    Redcar.event :foo
    assert widget.sensitive?
    @on = false
    Redcar.event :foo
    assert !widget.sensitive?
    widget.desensitize
    @on = true
    Redcar.event :foo
    assert !widget.sensitive?
  end
end
  
