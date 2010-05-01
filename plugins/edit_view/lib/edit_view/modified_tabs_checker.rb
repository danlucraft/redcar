module Redcar
  class EditView
    class ModifiedTabsChecker
      def initialize(tabs, message, options)
        @tabs, @message, @options = tabs, message, options
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
              Project::FileSaveCommand.new(t).run
            end
            @options[:continue] ? @options[:continue].call : nil
          when :no
            @options[:continue] ? @options[:continue].call : nil
          when :cancel
            @options[:cancel] ? @options[:cancel].call : nil
          end
        else
          @options[:none] ? @options[:none].call : nil
        end
      end
    end
  end
end
    