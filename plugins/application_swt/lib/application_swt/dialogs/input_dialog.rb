module Redcar
  class ApplicationSWT
    module Dialogs
      class InputDialog < JFace::Dialogs::Dialog
        def initialize(parent_shell, title, message, options={})
          super(parent_shell)
          @title, @message = title, message
          @options = {:password => false, :initial_text => ""}.merge(options)
        end
        
        def password?
          @options[:password]
        end
        
        def initial_text
          @options[:initial_text]
        end
        
        def createDialogArea(parent)
          composite = super(parent)
          
          passwordLabel = Swt::Widgets::Label.new(composite, Swt::SWT::RIGHT)
          passwordLabel.setText(@message)
          
          style = Swt::SWT::SINGLE
          style = style | Swt::SWT::PASSWORD if password?
          @inputField = Swt::Widgets::Text.new(composite, style)
          data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_HORIZONTAL)
          @inputField.setLayoutData(data)
          @inputField.setText(initial_text)
          
          getShell.setText(@title)
        end
        
        def value
          @text
        end
        
        def close
          @text = @inputField.getText
          super
        end
      end
    end
  end
end