module Redcar
  class OutlineViewSWT < Redcar::ApplicationSWT::FilterListDialogController
    include Redcar::Controller
    
    ICON_PATH = File.expand_path(File.dirname(__FILE__) + "/icons")
    
    ICONS = {
      :method => File.join(ICON_PATH, "method.png"),
      :class => File.join(ICON_PATH, "class.png"),
      :attribute => File.join(ICON_PATH, "attribute.png"),
      :alias => File.join(ICON_PATH, "alias.png"),
      :assignment => File.join(ICON_PATH, "assignment.png")
    }
    
    class OutlineViewDialogSWT < Redcar::ApplicationSWT::FilterListDialogController::FilterListDialog
      attr_reader :list, :text
      attr_accessor :controller
      
      def createDialogArea(parent)
        composite = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
        layout = Swt::Layout::RowLayout.new(Swt::SWT::VERTICAL)
        composite.setLayout(layout)
        @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
        @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
        @list = Swt::Widgets::Table.new(composite, Swt::SWT::V_SCROLL | Swt::SWT::H_SCROLL | Swt::SWT::MULTI)
        @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
        controller.attach_listeners
        controller.update_list_sync
        get_shell.add_shell_listener(Redcar::ApplicationSWT::FilterListDialogController::ShellListener.new(controller))
        Redcar::ApplicationSWT.register_shell(get_shell)
        Redcar::ApplicationSWT.register_dialog(get_shell, self)
        @list.set_selection(0)
      end
    end
    
    def initialize(model)
      @model = model
      @dialog = OutlineViewDialogSWT.new(Redcar.app.focussed_window.controller.shell)
      @dialog.controller = self
      if Redcar::ApplicationSWT::FilterListDialogController.test_mode?
        @dialog.setBlockOnOpen(false)
        @dialog.setShellStyle(Swt::SWT::DIALOG_TRIM)
      end
      attach_model_listeners
    end
    
    def update_list_sync
      if @dialog
        s = Time.now
        hash = @model.update_list(@dialog.text.get_text)
        populate_table(hash)
        @dialog.list.set_selection(0)
        text_focus
      end
    end
    
    private
    
    def populate_table(hash = {})
      @dialog.list.removeAll
      hash.each do |_, props|
        item = Swt::Widgets::TableItem.new(@dialog.list, Swt::SWT::NONE)
        item.text = props[0]
        icon = ICONS[props[1].to_sym]
        if icon
          image = Swt::Graphics::Image.new(ApplicationSWT.display, icon)
          item.image = image
        end
      end
    end
  end
end
