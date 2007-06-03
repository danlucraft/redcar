

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestDialog < Test::Unit::TestCase
  def setup
    startup
  end
  def teardown
    shutdown
  end
  
  def test_default_settings
    d = Redcar::Dialog.build :message => "message!"
    d.show
    d.press_button :ok
    assert d.dialog.destroyed?
  end
  
  def test_one_button_dialog
    button_pressed = false
    dialog = Redcar::Dialog.build :title => "Dialog1",
                                  :buttons => [:ok]
    dialog.on_button :ok do 
      button_pressed = true
      dialog.close
    end
    dialog.show
    assert_equal "Dialog1", dialog.dialog.title
    dialog.press_button :ok
    assert button_pressed
    assert dialog.dialog.destroyed?
  end
  
  def test_text_entry_dialog
    dialog = Redcar::Dialog.build :title => "Dialog2",
                                  :buttons => [:Switch, :ok],
                                  :entry => [
                                             {:name => :text1, :type => :text},
                                             {:name => :text2, :type => :text}
                                             ]
    dialog.on_button :switch do 
      dialog.text2 = dialog.text1 # this uses both the getter and setter
    end
    dialog.text1 = "foobar"
    dialog.show
    assert_equal "foobar", dialog.text1
    assert_equal "", dialog.text2
    dialog.press_button :switch
    assert_equal "foobar", dialog.text2
    dialog.press_button :ok
    assert dialog.dialog.destroyed?
  end
  
  def test_modality
    # TODO: how to test this??
  end
  
  def test_list
    val = nil
    list = Redcar::GUI::List.new :type => String, :heading => "head"
    d = Redcar::Dialog.build :title => "List Test",
                             :buttons => [:ok, :Select],
                             :entry => [{:name => :list, :type => :list, :abs => list}]
    d.list.replace ["item1", "item2", "item3"]
    d.list << "item4"
    assert_equal ["item1", "item2", "item3", "item4"], list.rows
    d.on_button :select do 
      d.list.select(3)
    end
    d.on_button :ok do 
      val = d.list.selected
      d.close
    end
    d.show
    d.press_button :select
    d.press_button :ok
    assert_equal "item4", val
  end
end


  
