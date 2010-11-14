require 'syntax_check/checker'
require 'syntax_check/error'

module Redcar
  module SyntaxCheck
    def self.remove_syntax_error_annotations(edit_view)
      edit_view.remove_all_annotations :type => Error::Type
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('syntax_checking')
        storage.set_default('suppress_message_dialogs',false)
        storage.set_default('suppress_syntax_checking',false)
        storage
      end
    end

    def self.message(message,type)
      unless SyntaxCheck.storage['suppress_message_dialogs']
        Redcar::Application::Dialog.message_box(
        message,{:type => type})
      end
    end

    def self.after_save(doc)
      unless SyntaxCheck.storage['suppress_syntax_checking']
        remove_syntax_error_annotations(doc.edit_view)
        checker = Checker[doc.edit_view.grammar]
        checker.new(doc).check if checker
      end
    end
  end
end