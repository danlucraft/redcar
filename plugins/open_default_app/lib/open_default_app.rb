module Redcar

  class OpenDefaultApp

    def self.project_context_menus(tree, node, controller)
      Menu::Builder.build do
        if node and node.path
          item ("Open Default App"){OpenDefaultAppCommand.new(node.path).run }
        end
      end
    end

    class OpenDefaultAppCommand < Redcar::Command
      import java.awt.Desktop

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def execute(options=nil)
        @path ||= options[:value]
        begin
          file  = java::io::File.new(path)
          if Desktop.is_desktop_supported()
            desktop = Desktop.get_desktop
            desktop.open(file)
          end
        rescue Object => e
          Application::Dialog.message_box("A default application could not be found for this type of file.")
        end
      end
    end
  end

  class OpenDefaultBrowserCommand < Redcar::Command
    import java.awt.Desktop

    attr_reader :uri

    def self.supported?
      Desktop.is_desktop_supported()
    end

    def initialize(uri)
      @uri = uri
    end

    def execute
      begin
        return unless OpenDefaultBrowserCommand.supported?
        URI::parse(@uri)
        parsed_uri = java.net.URI.new(@uri)
        Desktop.get_desktop.browse(parsed_uri)
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid URI given"
      end
    end
  end
end
