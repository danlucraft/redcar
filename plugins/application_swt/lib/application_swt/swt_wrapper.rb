$:.unshift(Redcar::ROOT + "/vendor/swt")

require 'rbconfig'

swt_lib = case Config::CONFIG["host_os"]
  when /darwin/i
    if Config::CONFIG["host_cpu"] == "x86_64"
      'osx64/swt'
    else
      'osx/swt'
    end
  when /linux/i
    if Config::CONFIG["host_cpu"] == "x86_64" || Config::CONFIG["host_cpu"] == "amd64"
      'linux64/swt'
    else
      'linux/swt'
    end
  when /windows|mswin/i
    'windows/swt'
end
 
require swt_lib

module Swt
  import org.eclipse.swt.SWT
  
  module Widgets
    import org.eclipse.swt.widgets.Display
    import org.eclipse.swt.widgets.Shell
    import org.eclipse.swt.widgets.Composite
    import org.eclipse.swt.widgets.Menu
    import org.eclipse.swt.widgets.MenuItem
  end
  
  module Layout
    import org.eclipse.swt.layout.FillLayout
  end
  
  module Graphics
    import org.eclipse.swt.graphics.Font
    import org.eclipse.swt.graphics.Point
  end
end
