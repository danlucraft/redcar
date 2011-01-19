require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::ApplicationSWT::Gradient do
  
  color_position_hash = {100 => "#000000", 0 => "#FFFFFF", 50 => "#999999"}
  subject { Redcar::ApplicationSWT::Gradient.new(color_position_hash) }
  
  it "should output its contents as a hash" do
    subject.to_hash.should == color_position_hash
  end
  
  describe "swt_stops" do
    
    it "not include the implied zero stop" do
      subject.swt_stops.should_not include(0)
    end
    
    it "should include nonzero stops from the input" do
      subject.swt_stops.to_a.should == [50, 100]
    end
    
    it "should be in increasing order" do
      subject.swt_stops.sort.should == subject.swt_stops.to_a
    end
    
  end
  
  describe "swt_colors" do
  
    it "should be Swt::Color versions of the gradient colors in increasing order by stop position" do
      subject.swt_colors[0].should == Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 255, 255, 255)
      subject.swt_colors[1].should == Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 153, 153, 153)
      subject.swt_colors[2].should == Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 0, 0, 0)
    end
    
  end
  
  context "when constructed with an implied 0-position stop" do
    
    subject { Redcar::ApplicationSWT::Gradient.new( 50 => "#000000", 100 => "#FFFFFF" ) }
    
    describe "swt_stops" do
      
      it "should have the first color position as its first element" do
        subject.swt_stops.first.should == 50
      end
      
    end
    
    describe "swt_colors" do
      
      it "should have the gradient's first color as its first two elements" do
        first_color = Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 0, 0, 0)
        subject.swt_colors[0].should == first_color
        subject.swt_colors[1].should == first_color
      end
      
    end
    
  end
  
  context "when constructed with an implied 100-position stop" do
    
    subject { Redcar::ApplicationSWT::Gradient.new( 0 => "#000000", 50 => "#FFFFFF" ) }
    
    describe "swt_stops" do
      
      it "should include a stop at position 100" do
        subject.swt_stops.should include(100)
      end
      
    end
    
    describe "swt_colors" do
      
      it "should have the gradient's last color as its last two elements" do
        last_color = Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 255, 255, 255)
        subject.swt_colors[1].should == last_color
        subject.swt_colors[2].should == last_color
      end
      
    end
    
  end
  
  context "when constructed with stop position below 0" do
    
    it "should raise an ArgumentError" do
      expect{ Redcar::ApplicationSWT::Gradient.new( -999 => "#FFFFFF") }.should raise_error(ArgumentError)
    end
    
  end
  
  context "when constructed with stop position above 100" do
    
    it "should raise an ArgumentError" do
      expect{ Redcar::ApplicationSWT::Gradient.new( 999 => "#FFFFFF") }.should raise_error(ArgumentError)
    end
    
  end
  
  context "when constructed with three-character hex strings for colors" do
    
    subject { Redcar::ApplicationSWT::Gradient.new( 50 => "#F0F" ) }
    
    it "should process the colors correctly" do
      subject.swt_colors[0].should == Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 255, 0, 255)
    end
    
  end
  
  context "when constructed with a single color instead of a gradient" do
  
    subject { Redcar::ApplicationSWT::Gradient.new( "#FFFFFF" ) }
  
    it "it should construct a gradient with that color" do
      subject.swt_colors[0].should == Swt::Graphics::Color.new(Redcar::ApplicationSWT.display, 255, 255, 255)
    end
  
  end
  
  context "when constructed with a color name" do
    
    subject { Redcar::ApplicationSWT::Gradient.new( "black" ) }
    
    it "should return the SWT system color corresponding to that name" do
      Redcar::ApplicationSWT.instance_variable_set("@display", Swt::Widgets::Display.current) if Redcar::ApplicationSWT.display.nil?
      subject.swt_colors[0].should == Redcar::ApplicationSWT.display.get_system_color(Swt::SWT::COLOR_BLACK)
    end
    
  end
end

