require "spec_helper"

describe Redcar::Speedbar do
  it "should let you add labels" do
    class LabelSpeedbar < Redcar::Speedbar
      label :label, "Here is a speedbar"
    end
    LabelSpeedbar.items.should == [Redcar::Speedbar::LabelItem.new(:label, "Here is a speedbar")]
  end

  it "should let you add toggles" do
    class ToggleSpeedbar < Redcar::Speedbar
      toggle :case_sensitive, "Case Sensitive", "Cmd+L"
    end
    ToggleSpeedbar.items.should == [Redcar::Speedbar::ToggleItem.new(:case_sensitive, "Case Sensitive", "Cmd+L", nil, false)]
  end
  
  it "should let you add textboxes" do
    class TextBoxSpeedbar < Redcar::Speedbar
      textbox :query
    end
    TextBoxSpeedbar.items.should == [Redcar::Speedbar::TextBoxItem.new(:query, nil, "")]
  end
  
  it "should let you add buttons" do
    class ButtonSpeedbar < Redcar::Speedbar
      button :search, "Search", "Ctrl+S"
    end
    ButtonSpeedbar.items.should == [Redcar::Speedbar::ButtonItem.new(:search, "Search", "Ctrl+S")]
  end

  it "should let you add combos" do
    class ComboSpeedbar < Redcar::Speedbar
      combo :tab_widths, %w"1 2 3 4", "1"
    end
    ComboSpeedbar.items.should == [Redcar::Speedbar::ComboItem.new(:tab_widths, %w(1 2 3 4), "1", false)]
  end

  it "should let you add editable combos" do
    class EditComboSpeedbar < Redcar::Speedbar
      combo :editable_combo, %w"1 2 3 4", "1", true 
    end
    EditComboSpeedbar.items.should == [Redcar::Speedbar::ComboItem.new(:editable_combo, %w(1 2 3 4), "1", true)]
  end

  it "should let you add keys" do
    class KeySpeedbar < Redcar::Speedbar
      key "Ctrl+S"
    end
    KeySpeedbar.items.should == [Redcar::Speedbar::KeyItem.new("Ctrl+S")]
  end
  
  it "should let you get values from instances" do
    class GetValueSpeedbar < Redcar::Speedbar
      textbox :query, "start"
    end
    sp = GetValueSpeedbar.new
    sp.query.value.should == "start"
  end
  
  it "should let you set values for instances" do
    class SetValueSpeedbar < Redcar::Speedbar
      textbox :query, "start"
    end
    sp = GetValueSpeedbar.new
    sp.query.value = "yoyo"
    sp.query.value.should == "yoyo"
   end
   
   it "should let only add an item with the same name once" do
     class TextBoxSpeedbar < Redcar::Speedbar
       textbox :query
       textbox :query
     end
     TextBoxSpeedbar.items.should == [Redcar::Speedbar::TextBoxItem.new(:query, nil, "")]
   end
end