
module Redcar
  class HtmlTab < Redcar::Tab

    def initialize(pane, source)
      hbox = Gtk::HBox.new
      @moz = Gtk::MozEmbed.new
      hbox.pack_start(@moz)
      super(pane, hbox, :scrolled => false)
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
