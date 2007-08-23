
require 'gtkmozembed'

module Redcar
  class << self
    attr_accessor :moz
  end
  
  class HtmlTab < Tab
    def initialize(inpane, source)
      hbox = Gtk.HBox.new
      @moz = Gtk.MozEmbed.new
      hbox.pack_start(@moz)
      super(inpane, hbox, :scrolled => false)
      Thread.new {
        sleep 0.5
        self.contents = source
      }
    end
    
    def contents=(source)
      @moz.render_data(source, "file://"+Dir.getwd+"/", "text/html")
    end
  end
end
