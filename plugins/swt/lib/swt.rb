
require 'rbconfig'

require 'swt/cucumber_runner'
require 'swt/event_loop'
require 'swt/listener_helpers'

module Swt
  SWT_APP_NAME = "Redcar"
  
  def self.jar_path
    case Config::CONFIG["host_os"]
    when /(darwin|linux)/i
      jar = ($1 == "linux" ? "linux" : "osx")
      jar << '64' if %w(amd64 x86_64).include? Config::CONFIG["host_cpu"]
      jar
    when /windows|mswin/i
      'win32'
    end
  end

  require File.join(Redcar.asset_dir, "swt/" + Swt.jar_path)

  import org.eclipse.swt.SWT

  def self.loaded
    @gui = Redcar::Gui.new("swt")
    @gui.register_event_loop(EventLoop.new)
    @gui.register_features_runner(CucumberRunner.new)
    Redcar.gui = @gui
  end
  
  class SplashScreen
    attr_reader :max
    
    def initialize(max)
      @max = max
      @current = 0
    end
    
    def show
      @image = Swt::Graphics::Image.new(Swt.display, Redcar::ICONS_DIRECTORY + "/redcar-splash.png")
      @splash = Swt::Widgets::Shell.new(Swt::SWT::NONE)
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
      progressData.left   = Swt::Layout::FormAttachment.new(0, 5)
      progressData.right  = Swt::Layout::FormAttachment.new(100, -5)
      progressData.bottom = Swt::Layout::FormAttachment.new(100, -5)
      @bar.setLayoutData(progressData)
      @splash.pack
      
      primary = Swt.display.getPrimaryMonitor
      bounds = primary.getBounds
      rect = @splash.getBounds
      x = bounds.x + (bounds.width - rect.width) / 2;
      y = bounds.y + (bounds.height - rect.height) / 2;
    
      @splash.setLocation(x, y)
      @splash.open
    end
    
    def inc(val = 1)
      @current += val
      @bar.setSelection([@current, @max].min)
    end
    
    def close
      @splash.close
      @image.dispose
      Swt.instance_variable_set(:@splashscreen, nil)
    end
  end
  
  class << self
    attr_reader :splash_screen
  end
  
  def self.create_splash_screen(maximum)
    @splash_screen = SplashScreen.new(maximum)
    splash_screen.show
  end
  
  # Runs the given block in the SWT Event thread
  def self.sync_exec(&block)
    return block.call if Redcar.no_gui_mode?
    runnable = Swt::RRunnable.new do
      begin
        block.call
      rescue => e
        puts "error in sync exec"
        puts e.message
        puts e.backtrace
      end
    end
    unless display.is_disposed
      display.syncExec(runnable)
    end
  end
  
  # Runs the given block in the SWT Event thread after
  # the given number of milliseconds
  def self.timer_exec(ms, &block)
    if Redcar.no_gui_mode?
      sleep ms.to_f/1000
      return block.call
    end
    runnable = Swt::RRunnable.new(&block)
    display.timerExec(ms, runnable)
  end

  module Widgets
    import org.eclipse.swt.widgets.Display
    import org.eclipse.swt.widgets.Label
    import org.eclipse.swt.widgets.ProgressBar
    import org.eclipse.swt.widgets.Shell
  end
  
  module Custom
  end
  
  module DND
  end
  
  module Layout
    import org.eclipse.swt.layout.FormAttachment
    import org.eclipse.swt.layout.FormData
    import org.eclipse.swt.layout.FormLayout
  end
  
  module Graphics
    import org.eclipse.swt.graphics.Image
  end
  
  module Events
  end
  
  class RRunnable
    include java.lang.Runnable

    def initialize(&block)
      @block = block
    end

    def run
      @block.call
    end
  end
  
  def self.display
    return nil if Redcar.no_gui_mode?
    if defined?(SWT_APP_NAME)
      Swt::Widgets::Display.app_name = SWT_APP_NAME
    end
    @display ||= (Swt::Widgets::Display.getCurrent || Swt::Widgets::Display.new)
  end

  unless Redcar.no_gui_mode?
    display # must be created before we import the Clipboard class.
  end
end
