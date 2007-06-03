
class HtmlWindow < Gtk::Window
  def initialize(name, source)
    super name
    htmlview = Gtk::HtmlView.new()
    htmlview.show

    doc = Gtk::HtmlDocument.new()
    doc.open_stream('text/html')
    doc.write_stream(source)
    doc.close_stream()

    doc.signal_connect( "link_clicked" ) {  |doc,link|
        puts "link_clicked #{link}"
        htmlview.document.clear
        htmlview.document.open_stream("text/html")
        htmlview.document.write_stream( "<html><body><h1>#{link}</h1></body></html>")
        htmlview.document.close_stream()
    }

    ##### sample handler for 'request_url' signal might look like this
    ##### (you need this to show images inside the widget)
    #doc.signal_connect('request_url') { |html_doc, url, stream|
    #   puts "request_url #{html_doc} #{url} #{stream}"
    #   File.open( File.expand_path(url) ) {|file| #TODO: here add argument for base_url
    #     puts "open success"
    #     data = file.read()
    #     stream.write(data)
    #     stream.close()
    #   }
    #}

    htmlview.document = doc
    
    add(htmlview)
    show_all
  end
end
