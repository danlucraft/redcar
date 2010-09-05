
require 'rbconfig'

require 'swt/cucumber_runner'
require 'swt/event_loop'
require 'swt/grid_data'
require 'swt/listener_helpers'

module Swt
  SWT_APP_NAME = "Redcar"
  
  def self.jar_path
    case Config::CONFIG["host_os"]
    when /darwin/i
      if Config::CONFIG["host_cpu"] == "x86_64"
        'osx64'
      else
        'osx'
      end
    when /linux/i
      if %w(amd64 x84_64).include? Config::CONFIG["host_cpu"]
        'linux64'
      else
        'linux'
      end
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
      @image = Swt::Graphics::Image.new(Swt.display, 300, 300)
      @splash = Swt::Widgets::Shell.new(Swt::SWT::ON_TOP)
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
    runnable = Swt::RRunnable.new(&block)
    display.timerExec(ms, runnable)
  end

  module Widgets
    import org.eclipse.swt.widgets.Button
    import org.eclipse.swt.widgets.Caret
    import org.eclipse.swt.widgets.Combo
    import org.eclipse.swt.widgets.Composite
    import org.eclipse.swt.widgets.Display
    import org.eclipse.swt.widgets.Event
    import org.eclipse.swt.widgets.DirectoryDialog
    import org.eclipse.swt.widgets.FileDialog
    import org.eclipse.swt.widgets.Label
    import org.eclipse.swt.widgets.List
    import org.eclipse.swt.widgets.Menu
    import org.eclipse.swt.widgets.MenuItem
    import org.eclipse.swt.widgets.MessageBox
    import org.eclipse.swt.widgets.ProgressBar
    import org.eclipse.swt.widgets.Sash
    import org.eclipse.swt.widgets.Shell
    import org.eclipse.swt.widgets.TabFolder
    import org.eclipse.swt.widgets.TabItem
    import org.eclipse.swt.widgets.Text
    import org.eclipse.swt.widgets.ToolTip
    import org.eclipse.swt.widgets.Table
    import org.eclipse.swt.widgets.TableItem
  end
  
  def self.display
    if defined?(SWT_APP_NAME)
      Swt::Widgets::Display.app_name = SWT_APP_NAME
    end
    @display ||= (Swt::Widgets::Display.getCurrent || Swt::Widgets::Display.new)
  end

  display # must be created before we import the Clipboard class.

  module Custom
    import org.eclipse.swt.custom.CTabFolder
    import org.eclipse.swt.custom.CTabItem
    import org.eclipse.swt.custom.SashForm
    import org.eclipse.swt.custom.StackLayout
    import org.eclipse.swt.custom.ST
    import org.eclipse.swt.custom.StyledText
    import org.eclipse.swt.custom.TreeEditor
  end
  
  module DND
    import org.eclipse.swt.dnd.DND
    import org.eclipse.swt.dnd.Clipboard
    import org.eclipse.swt.dnd.Transfer
    import org.eclipse.swt.dnd.TextTransfer
    import org.eclipse.swt.dnd.FileTransfer
    import org.eclipse.swt.dnd.ByteArrayTransfer
    
    import org.eclipse.swt.dnd.DropTarget
    import org.eclipse.swt.dnd.DropTargetEvent
    import org.eclipse.swt.dnd.DropTargetListener
    
    import org.eclipse.swt.dnd.DragSource
    import org.eclipse.swt.dnd.DragSourceEvent
    import org.eclipse.swt.dnd.DragSourceListener
  end
  
  module Layout
    import org.eclipse.swt.layout.FillLayout
    import org.eclipse.swt.layout.FormAttachment
    import org.eclipse.swt.layout.FormLayout
    import org.eclipse.swt.layout.FormData
    import org.eclipse.swt.layout.GridLayout
    import org.eclipse.swt.layout.GridData
    import org.eclipse.swt.layout.RowLayout
    import org.eclipse.swt.layout.RowData
  end
  
  module Graphics
    import org.eclipse.swt.graphics.Color
    import org.eclipse.swt.graphics.Device
    import org.eclipse.swt.graphics.Font
    import org.eclipse.swt.graphics.GC
    import org.eclipse.swt.graphics.Image
    import org.eclipse.swt.graphics.Point
  end
  
  module Events
    import org.eclipse.swt.events.KeyEvent
  end
  
  import org.eclipse.swt.browser.Browser
  class Browser
    import org.eclipse.swt.browser.BrowserFunction
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
end

module JFace
  Dir[Redcar.asset_dir + "/jface/*.jar"].each do |jar_fn|
    require jar_fn
  end
  
  module Viewers
    import org.eclipse.jface.viewers.ColumnViewerToolTipSupport
    import org.eclipse.jface.viewers.TreeViewer
    import org.eclipse.jface.viewers.ITreeContentProvider
    import org.eclipse.jface.viewers.ILabelProvider
    import org.eclipse.jface.viewers.ILazyTreeContentProvider
    import org.eclipse.jface.viewers.ILabelProvider
    import org.eclipse.jface.viewers.TextCellEditor
    import org.eclipse.jface.viewers.ViewerDropAdapter
  end
  
  module Text
    import org.eclipse.jface.text.TextViewerUndoManager
  end
  
  module Dialogs
    import org.eclipse.jface.dialogs.Dialog
    import org.eclipse.jface.dialogs.InputDialog
  end
end
