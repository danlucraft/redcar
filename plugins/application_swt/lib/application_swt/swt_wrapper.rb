
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
  
  class Swt::Widgets::Shell
    
    def on_close &block
      listener.add_close_event &block
    end
    
    def listener
      if @listener
        @listener
      else
        @listener = Redcar::ApplicationSWT::ShellListener.new
        self.add_shell_listener(@listener)  
        @listener
      end
    end
  end
end
# 
# require File.dirname(__FILE__) + "/../../vendor/jface/org.eclipse.jface.jar"
# 
# module JFace
#   module Bindings
#     module Keys
#       import org.eclipse.jface.bindings.keys.KeyStroke
#     end
#   end
# end
# 
# 
# Dir["plugins/application_swt/vendor/swtbot/*.jar"].each do |fn|
#   next if fn =~ /source/
#   p fn
#   require fn
# end
# 
# Dir[File.dirname(__FILE__) + "/../../vendor/swtbot/*.jar"].each do |fn|
#   next if fn =~ /source/
#   p fn
#   require fn
# end

# module SwtBot
#   module Finder
#     import org.eclipse.swtbot.swt.finder.SWTBot
#   end
# end

# p SwtBot::Finder::SWTBot


