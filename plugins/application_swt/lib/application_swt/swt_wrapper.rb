
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
  
  require File.dirname(__FILE__) + "/../../vendor/swt/" + Swt.jar_path

  import org.eclipse.swt.SWT
  
  module Widgets
    import org.eclipse.swt.widgets.Button
    import org.eclipse.swt.widgets.Display
    import org.eclipse.swt.widgets.Shell
    import org.eclipse.swt.widgets.Composite
    import org.eclipse.swt.widgets.Label
    import org.eclipse.swt.widgets.Menu
    import org.eclipse.swt.widgets.MenuItem
    import org.eclipse.swt.widgets.Text
  end
  
  module Layout
    import org.eclipse.swt.layout.FillLayout
    import org.eclipse.swt.layout.RowLayout
  end
  
  module Graphics
    import org.eclipse.swt.graphics.Font
    import org.eclipse.swt.graphics.Point
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
