require 'rbconfig'

module Swt
  def self.jar_path
    case Config::CONFIG["host_os"]
    when /darwin/i
      if Config::CONFIG["host_cpu"] == "x86_64"
        'osx64/swt'
      else
        'osx/swt'
      end
    when /linux/i
      if %w(amd64 x84_64).include? Config::CONFIG["host_cpu"]
        'linux64/swt'
      else
        'linux/swt'
      end
    when /windows|mswin/i
      'win32/swt'
    end
  end

  path = File.expand_path(File.dirname(__FILE__) + "/../../vendor/swt/" + Swt.jar_path)
  if File.exist?(path + ".jar")
    puts "loading #{Swt.jar_path}"
    require path
  else
    puts "SWT jar file required: #{path}.jar"
    exit
  end

  import org.eclipse.swt.SWT
  
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
    import org.eclipse.swt.widgets.Sash
    import org.eclipse.swt.widgets.Shell
    import org.eclipse.swt.widgets.TabFolder
    import org.eclipse.swt.widgets.TabItem
    import org.eclipse.swt.widgets.Text
    import org.eclipse.swt.widgets.ToolTip
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
  Dir[File.dirname(__FILE__) + "/../../vendor/jface/*.jar"].each do |jar_fn|
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
