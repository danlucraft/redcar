require 'syntax_check/checker'
require 'syntax_check/annotation'

module Redcar
  module SyntaxCheck
    def self.remove_syntax_error_annotations(edit_view)
      edit_view.remove_all_annotations :type => Annotation.type
      edit_view.remove_all_annotations :type => Warning.type
      edit_view.remove_all_annotations :type => Error.type
    end

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Plugins" do
          lazy_sub_menu "Syntax Checking" do
            item "Enabled", :type => :check, :active => SyntaxCheck.enabled?, :command => ToggleSyntaxChecking
            separator
            Checker.checkers.each do |checker|
              grammar = checker[0]
              item "#{grammar}", :type => :check, :active => SyntaxCheck.check_type?(grammar), :command => ToggleGrammarChecking, :value => grammar
            end
          end
        end
      end
    end

    def self.enabled=(state)
      SyntaxCheck.storage['suppress_syntax_checking'] = !state
    end

    def self.enabled?
      if SyntaxCheck.storage['suppress_syntax_checking']
        false
      else
        true
      end
    end

    def self.check_type?(grammar)
      excluded = SyntaxCheck.storage['excluded_grammars']
      unless grammar and (excluded.include? grammar or
        excluded.include? grammar.downcase)
        true
      end
    end

    def self.set_check_type(grammar,value)
      if grammar
        excluded = SyntaxCheck.storage['excluded_grammars']
        if check_type?(grammar)
          excluded << grammar.downcase
        else
          excluded = excluded - [grammar,grammar.downcase]
        end
        SyntaxCheck.storage['excluded_grammars'] = excluded
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('syntax_checking')
        storage.set_default('suppress_message_dialogs',false)
        storage.set_default('suppress_syntax_checking',false)
        storage.set_default('excluded_grammars',[])
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
      grammar  = doc.edit_view.grammar
      remove_syntax_error_annotations(doc.edit_view)
      if SyntaxCheck.enabled? and SyntaxCheck.check_type?(grammar)
        checker = Checker[doc.edit_view.grammar]
        checker.new(doc).check if checker
      end
    end

    class ToggleGrammarChecking < Redcar::Command
      def execute(options)
        if grammar = options[:value]
          value = !SyntaxCheck.check_type?(grammar)
          SyntaxCheck.set_check_type(grammar,value)
        end
      end
    end

    class ToggleSyntaxChecking < Redcar::Command
      def execute
        SyntaxCheck.enabled = !SyntaxCheck.enabled?
      end
    end
  end
end
