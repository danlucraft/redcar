module Redcar
  class ApplicationSWT
    class DialogAdapter
      def open_file(window, options)
        dialog = Swt::Widgets::FileDialog.new(window.controller.shell, Swt::SWT::OPEN)
        if options[:filter_path]
          dialog.set_filter_path(options[:filter_path])
        end
        dialog.open
      end
    end
  end
end