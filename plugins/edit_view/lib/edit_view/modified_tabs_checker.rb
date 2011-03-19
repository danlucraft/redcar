module Redcar
  class EditView
    class ModifiedTabsChecker
      def initialize(tabs, message)
        @tabs, @message = tabs, message
      end
      
      def check
        modified_edit_tabs = @tabs.select {|t| t.edit_view.document.modified? }
        if modified_edit_tabs.any?
          result = Application::Dialog.message_box(
            "You have #{modified_edit_tabs.length} modified tabs.\n\n" + 
            @message,
            :buttons => :yes_no_cancel
          )
          case result
          when :yes
            modified_edit_tabs.each do |t|
              t.focus
              Project::SaveFileCommand.new(t).run
            end
            true
          when :no
            true
          when :cancel
            false
          end
        else
          true
        end
      end
    end
  end
end
    