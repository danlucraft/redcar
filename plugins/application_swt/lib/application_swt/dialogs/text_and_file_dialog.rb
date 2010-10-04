
module Redcar
  class ApplicationSWT
    module Dialogs
      class TextAndFileDialog < JFace::Dialogs::Dialog

        CONTINUE_BUTTON = "Continue"
        BROWSE_BUTTON = "Browse"
        # TODO: refactor this mess!
        def set_text(title,message_1,message_2)
          @title = title
          @message_1 = message_1
          @message_2 = message_2
        end

        def result
          @result
        end

        def set_result(result)
          @result = result
        end

        def createContents(parent)
          composite = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
          composite.setLayout(Swt::Layout::FormLayout.new)
          composite.setSize(480,200)
          composite.shell.setText(@title)

          target_label = Swt::Widgets::Label.new(composite, Swt::SWT::NONE)
          target_labelLData = Swt::Layout::FormData.new
          target_labelLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 12)
          target_labelLData.top = Swt::Layout::FormAttachment.new(0, 1000, 78)
          target_labelLData.width = 200
          target_labelLData.height = 17
          target_label.setLayoutData(target_labelLData)
          target_label.setText(@message_2)

          dialog_message = Swt::Widgets::Label.new(composite, Swt::SWT::NONE);
          dialog_messageLData = Swt::Layout::FormData.new
          dialog_messageLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 12)
          dialog_messageLData.top =  Swt::Layout::FormAttachment.new(0, 1000, 6)
          dialog_messageLData.width = 200
          dialog_messageLData.height = 17
          dialog_message.setLayoutData(dialog_messageLData)
          dialog_message.setText(@message_1)

          continue_button = Swt::Widgets::Button.new(composite, Swt::SWT::PUSH | Swt::SWT::CENTER)
          continueLData = Swt::Layout::FormData.new
          continueLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 146)
          continueLData.top =  Swt::Layout::FormAttachment.new(0, 1000, 141)
          continueLData.width = 70
          continueLData.height = 30
          continue_button.setLayoutData(continueLData)
          continue_button.setText(CONTINUE_BUTTON)

          browse_files = Swt::Widgets::Button.new(composite, Swt::SWT::PUSH | Swt::SWT::CENTER)
          browse_files.setText(BROWSE_BUTTON)
          browse_filesLData = Swt::Layout::FormData.new
          browse_filesLData.width = 70
          browse_filesLData.height = 30
          browse_filesLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 310)
          browse_filesLData.top =  Swt::Layout::FormAttachment.new(0, 1000, 110)
          browse_files.setLayoutData(browse_filesLData)

          target_dirLData = Swt::Layout::FormData.new
          target_dirLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 12)
          target_dirLData.top =  Swt::Layout::FormAttachment.new(0, 1000, 110)
          target_dirLData.width = 300
          target_dirLData.height = 22
          target_dir = Swt::Widgets::Text.new(composite, Swt::SWT::NONE)
          target_dir.setLayoutData(target_dirLData)

          repo_urlLData = Swt::Layout::FormData.new
          repo_urlLData.left =  Swt::Layout::FormAttachment.new(0, 1000, 12)
          repo_urlLData.top =  Swt::Layout::FormAttachment.new(0, 1000, 38)
          repo_urlLData.width = 300
          repo_urlLData.height = 22
          repo_url = Swt::Widgets::Text.new(composite, Swt::SWT::NONE)
          repo_url.setLayoutData(repo_urlLData)

          listener = SelectionListener.new(self,composite,repo_url,target_dir)
          browse_files.addListener(Swt::SWT::Selection, listener)
          continue_button.addListener(Swt::SWT::Selection, listener)

          composite
        end

        def open
          super
          @result
        end

        class SelectionListener
          def initialize(parent,dialog,repo_url,target_dir)
            @dialog = dialog.shell
            @repo_url = repo_url
            @target_dir = target_dir
            @parent = parent
          end

          def handleEvent(event)
            if (event.widget.getText == BROWSE_BUTTON)
              target_dir_path = Application::Dialog.open_directory({})
              @target_dir.setText(target_dir_path) if target_dir_path
            elsif (event.widget.getText == CONTINUE_BUTTON)
              @parent.set_result({
                :text => @repo_url.text,
                :directory => @target_dir.text
              })
              @dialog.close
            end
          end
        end
      end
    end
  end
end