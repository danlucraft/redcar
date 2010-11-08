module Redcar
  class ApplicationSWT
    class Speedbar
      class TextBoxItem
        def initialize(speedbar, composite, item)
          edit_view = EditView.new
          item.edit_view = edit_view
          edit_view_swt = EditViewSWT.new(edit_view, composite, :single_line => true)
          mate_text = edit_view_swt.mate_text
          mate_text.set_font(EditView.font, EditView.font_size)
          mate_text.getControl.set_text(item.value)
          mate_text.set_grammar_by_name "Ruby"
          mate_text.set_theme_by_name(EditView.theme)
          mate_text.set_root_scope_by_content_name("Ruby", "string.regexp.classic.ruby")
          gridData = Swt::Layout::GridData.new
          gridData.grabExcessHorizontalSpace = true
          gridData.horizontalAlignment = Swt::Layout::GridData::FILL
          mate_text.getControl.set_layout_data(gridData)
          edit_view.document.add_listener(:changed) do
            speedbar.ignore(item.name) do
              item.value = edit_view.document.to_s
              speedbar.execute_listener_in_model(item, item.value)
            end
          end
          item.add_listener(:changed_value) do |new_value|
            speedbar.ignore(item.name) do
              mate_text.getControl.set_text(new_value)
            end
          end
          speedbar.keyable_widgets << mate_text.getControl
          speedbar.focussable_widgets << mate_text.getControl
        end
      end
    end
  end
end
