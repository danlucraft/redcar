require "java"
#load a markdown4j jar
#depends: https://code.google.com/p/markdown4j/
Dir[File.join(Redcar.root, %w(plugins markdown vendor *.jar))].each {|jar| require jar }

module Redcar
  class Markdown
    def self.keymaps
      map = Redcar::Keymap.build("main", [:osx, :linux, :windows]) do
        link "Alt+Shift+Q", MarkdownPreviewCommand
      end
      [map]
    end

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "File" do
          item "Markdown Preview", :command => MarkdownPreviewCommand, :priority => 8
        end
      end
    end

    class MarkdownPreviewCommand < Redcar::EditTabCommand
      def execute
        mirror, text = doc.mirror, doc.get_all_text

        name = if mirror && path = mirror.path && File.exists?(mirror.path)
           "Preview: #{File.basename(mirror.path)}"
        else
          "Preview"
        end

        html = MarkdownConverter::Markdown4jProcessor.new.process(text)

        preview = java.io.File.createTempFile("preview",".html")
        preview.deleteOnExit
        path    = preview.get_absolute_path

        File.open(path,'w') {|f| f.puts(html)}

        Redcar::HtmlView::DisplayWebContent.new(name, path, false).run
      end
    end

    module MarkdownConverter
      include_package "org.markdown4j"
    end
  end
end