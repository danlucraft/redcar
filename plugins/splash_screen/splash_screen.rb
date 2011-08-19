module Redcar
  class SplashScreen
    class << self
      attr_reader :splash_screen
    end
    
    def self.create_splash_screen(maximum)
      @splash_screen = SplashScreen.new(maximum)
      splash_screen.show
    end

    attr_reader :max
    
    def initialize(max)
      @max = max
      @current = 0
    end
    
    def show
      @image = Swt::Graphics::Image.new(Swt.display, Redcar.icons_directory + "/redcar-splash.png")
      @splash = Swt::Widgets::Shell.new(Swt::SWT::NO_TRIM)
      @bar = Swt::Widgets::ProgressBar.new(@splash, Swt::SWT::NONE)
      @bar.setMaximum(max)
      label = Swt::Widgets::Label.new(@splash, Swt::SWT::NONE)
      label.setImage(@image)
      layout = Swt::Layout::FormLayout.new
      @splash.setLayout(layout)
      labelData = Swt::Layout::FormData.new
      labelData.right  = Swt::Layout::FormAttachment.new(100, 0)
      labelData.bottom = Swt::Layout::FormAttachment.new(100, 0)
      label.setLayoutData(labelData)
      progressData = Swt::Layout::FormData.new
      progressData.left   = Swt::Layout::FormAttachment.new(0, 70)
      progressData.right  = Swt::Layout::FormAttachment.new(100, -32)
      progressData.bottom = Swt::Layout::FormAttachment.new(100, -30)
      @bar.setLayoutData(progressData)
      @splash.pack
      
      primary = Swt.display.getPrimaryMonitor
      bounds = primary.getBounds
      rect = @splash.getBounds
      x = bounds.x + (bounds.width - rect.width) / 2;
      y = bounds.y + (bounds.height - rect.height) / 2;
    
      @splash.setLocation(x, y)
      @splash.open
      Redcar.log.debug("opened splash")
    end
    
    def inc(val = 1)
      @current += val
      @bar.setSelection([@current, @max].min)
    end
    
    def close
      @splash.close
      @image.dispose
      Swt.instance_variable_set(:@splashscreen, nil)
      Redcar.log.debug("closed splash")
    end
  end
end
