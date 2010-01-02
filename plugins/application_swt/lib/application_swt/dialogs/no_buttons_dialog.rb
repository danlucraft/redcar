module Redcar
  class ApplicationSWT
    module Dialogs
      # A type of JFace Dialog with no button bar.
      class NoButtonsDialog < JFace::Dialogs::Dialog
      
        def createContents(parent)
          composite = Swt::Widgets::Composite.new(parent, 0)
          layout = Swt::Layout::GridLayout.new
          layout.marginHeight = 0
          layout.marginWidth = 0
          layout.verticalSpacing = 0
          composite.setLayout(layout)
          composite.setLayoutData(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
          JFace::Dialogs::Dialog.applyDialogFont(composite)
          initializeDialogUnits(composite)
          dialogArea = createDialogArea(composite)
          
          composite
        end
      end
    end
  end
end