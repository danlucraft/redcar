require 'syntax_check/checker'
require 'syntax_check/error'

module Redcar
  module SyntaxCheck
    def self.remove_syntax_error_annotations(edit_view)
      edit_view.remove_all_annotations :type => Error::Type
    end

    def self.after_save(doc)
      remove_syntax_error_annotations(doc.edit_view)
      checker = Checker[doc.edit_view.grammar]
      checker.new(doc).check if checker
    end
  end
end