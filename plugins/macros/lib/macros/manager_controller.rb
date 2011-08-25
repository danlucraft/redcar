
module Redcar
  module Macros
    class ManagerController
      include Redcar::HtmlController

      def title
        "Macro Manager"
      end
      
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "..", "views", "macro_manager.html.erb")))
        rhtml.result(binding)
      end
      
      def assign_name(macro_name)
        Macros.name_macro(macro_name, "Assign a name:")        
        nil
      end
      
      def rename_macro(macro_name)
        Macros.rename_macro(macro_name)
        nil
      end
      
      def delete_macro(macro_name)
        Macros.delete_macro(macro_name)
        nil
      end
      
      def macro_steps(macro)
        html = ""
        html << <<-HTML
        <tr style="display: none;" class="macro-actions">
          <td colspan="4">
            <table>
        HTML

        macro.actions.each do |action|
          case action
          when Fixnum
            a = " "
            a[0] = action
            s = "Insert: #{a.inspect}"
          when Symbol
            s = "Navigation: #{action}"
          when DocumentCommand
            s = "Command: #{action.inspect.gsub("<", "&lt;").gsub(">", "&gt;")}"
          else
            raise "don't know what kind of action #{action.inspect} is"
          end
          html << <<-HTML
            <tr><td>#{s}</td></tr>
          HTML
        end
        
        html << <<-HTML
            </table>
          </td>
        </tr>
        HTML
        
        html
      end
    end
  end
end