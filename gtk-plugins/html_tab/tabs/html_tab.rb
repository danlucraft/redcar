
module Redcar
  class HtmlTab < Redcar::Tab

    def initialize(pane, source)
      hbox = Gtk::HBox.new
      @wv = Gtk::WebKit::WebView.new
      hbox.pack_start(@wv)
      super(pane, hbox, :scrolled => false)
      @contents = source
      render_contents
    end
    
    def render_contents
      @wv.load_html_string(@contents)
    end
    
    # This only returns contents that have been set with contents=
    def visible_contents_as_string
      @contents
    end
  end
end
