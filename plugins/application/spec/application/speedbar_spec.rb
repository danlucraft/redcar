require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Speedbar do
  it "should let you add labels" do
    class LabelSpeedbar < Redcar::Speedbar
      label "Here is a speedbar"
    end
    LabelSpeedbar.items.should == [Redcar::Speedbar::LabelItem.new("Here is a speedbar")]
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
      button :search, "Ctrl+S"
    end
    ButtonSpeedbar.items.should == [Redcar::Speedbar::ButtonItem.new(:search, "Ctrl+S")]
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
    sp = GetValueSpeedbar.new(self)
    sp.query.should == "start"
  end
end