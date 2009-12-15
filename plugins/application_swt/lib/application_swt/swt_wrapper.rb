
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
      'windows/swt'
    end
  end

  path = File.expand_path(File.dirname(__FILE__) + "/../../vendor/swt/" + Swt.jar_path)
  if File.exist?(path + ".jar")
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
    import org.eclipse.swt.widgets.FileDialog
    import org.eclipse.swt.widgets.Label
    import org.eclipse.swt.widgets.Menu
    import org.eclipse.swt.widgets.MenuItem
    import org.eclipse.swt.widgets.Shell
    import org.eclipse.swt.widgets.TabFolder
    import org.eclipse.swt.widgets.TabItem
    import org.eclipse.swt.widgets.Text
  end

  module Custom
    import org.eclipse.swt.custom.CTabFolder
    import org.eclipse.swt.custom.CTabItem
    import org.eclipse.swt.custom.SashForm
  end
  
  module Layout
    import org.eclipse.swt.layout.FillLayout
    import org.eclipse.swt.layout.GridLayout
    import org.eclipse.swt.layout.GridData
    import org.eclipse.swt.layout.RowLayout
  end
  
  module Graphics
    import org.eclipse.swt.graphics.Color
    import org.eclipse.swt.graphics.Font
    import org.eclipse.swt.graphics.GC
    import org.eclipse.swt.graphics.Image
    import org.eclipse.swt.graphics.Point
  end
  
  module Events
    import org.eclipse.swt.events.KeyEvent
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
    import org.eclipse.jface.viewers.TreeViewer
    import org.eclipse.jface.viewers.ITreeContentProvider
    import org.eclipse.jface.viewers.ILabelProvider
  end
end







