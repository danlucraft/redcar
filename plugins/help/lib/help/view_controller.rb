module Redcar
  class Help
    class ViewController
      include HtmlController

      def title
        "Shortcuts"
      end

      def clean_name(command)
        name = command.to_s.sub("Command","")
        idx = name.rindex("::")
        unless idx.nil?
          name = name[idx+2,name.length]
        end
        name = name.split(/(?=[A-Z])/).map{|w| w}.join(" ").sub("R E P L","REPL")
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
      
      def add_key_binding(key, command)
        return unless key && key.length > 0
        Redcar::KeyBindings.add_key_binding key, command
      end
    end
  end
end