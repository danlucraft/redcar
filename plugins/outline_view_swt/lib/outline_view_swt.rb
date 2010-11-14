module Redcar
  class OutlineViewSWT < Redcar::ApplicationSWT::FilterListDialogController
    include Redcar::Controller

    ICONS = {
      :method => ApplicationSWT::Icon.swt_image(:node_insert),
      :class => ApplicationSWT::Icon.swt_image(:open_source_flipped),
      :attribute => ApplicationSWT::Icon.swt_image(:status),
      :alias => ApplicationSWT::Icon.swt_image(:arrow_branch),
      :assignment => ApplicationSWT::Icon.swt_image(:arrow),
      :interface => ApplicationSWT::Icon.swt_image(:information),
      :closure => ApplicationSWT::Icon.swt_image(:node_magnifier),
      :none => nil
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
      @associations = {}
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

    def selected
      @model.selected(@associations[@dialog.list.get_selection.first])
    end

    private

    def populate_table(hash = {})
      @dialog.list.removeAll; @associations.clear
      hash.each do |match, props|
        props = {:kind => :none, :name => ""}.merge(props)
        item = Swt::Widgets::TableItem.new(@dialog.list, Swt::SWT::NONE)
        @associations[item] = match
        item.text = props[:name]
        image = ICONS[props[:kind].to_sym] if props[:kind]
        if image
          item.image = image
        end
      end
    end
  end
end
