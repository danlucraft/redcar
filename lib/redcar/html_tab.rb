
require 'gtkmozembed'

module Redcar
  class << self
    attr_accessor :moz
  end
  
  class HtmlTab < Tab
    def initialize(pane, source)
      hbox = Gtk::HBox.new
      @moz = Redcar.moz
      if @moz.parent
        @moz.reparent(hbox)
      else
        hbox.pack_start(@moz)
      end
      
      super(pane, hbox, :scrolled => false)
      Thread.new {
        sleep 0.05
        self.contents = source
      }
    end
    
    def contents=(source)
      @moz.render_data(source, "file://"+Dir.getwd+"/", "text/html")
    end
  end
end
