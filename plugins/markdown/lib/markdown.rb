require "java"
require "rexml/document"
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

        name, project_path = if mirror && path = mirror.path && File.exists?(mirror.path)
           ["Preview: #{File.basename(mirror.path)}", File.dirname(mirror.path)]
        else
          ["Preview", Dir.home]
        end

        source = MarkdownConverter::Markdown4jProcessor.new.process(text)

        preview = java.io.File.createTempFile("preview",".html")
        preview.deleteOnExit
        path    = preview.get_absolute_path

        doc = REXML::Document.new("<html>#{source}</html>")

        REXML::XPath.each(doc, "//img") do |img|
          src = img.attribute("src")
          if src && src.value && !src.value.start_with?("http")
            img.add_attribute("src", File.absolute_path("#{project_path}/#{src.value}"))
          end
        end

        File.open(path,'w') {|f| f.puts(doc)}

        Redcar::HtmlView::DisplayWebContent.new(name, path, false).run
      end
    end

    module MarkdownConverter
      include_package "org.markdown4j"
    end
  end
end