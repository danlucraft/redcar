
module Redcar
  class HtmlTab < Redcar::Tab

    def initialize(pane, source)
      hbox = Gtk::HBox.new
      @moz = Gtk::MozEmbed.new
      hbox.pack_start(@moz)
      super(pane, hbox, :scrolled => false)
      @contents = source
      
      # God this is hacky. I can haz Webkit plz?
      Thread.new {
        sleep 1
        render_contents
      }
    end
    
    def render_contents
      @moz.render_data(@contents, "file://"+Dir.getwd+"/", "text/html")
    end
    
    # This only returns contents that have been set with contents=
    def visible_contents_as_string
      @contents
    end
  end
end
