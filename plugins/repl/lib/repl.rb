
require 'repl/repl_mirror'
require 'repl/repl_tab'
require 'repl/repl_command'

module Redcar
  class REPL

    DEFAULT_BUFFER_SIZE = 15

    def self.sensitivities
      [
        Sensitivity.new(:open_repl_tab, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and
          tab.is_a?(REPL::Tab) and
          tab.edit_view.document.mirror.is_a?(REPL::ReplMirror)
        end
      ]
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('repl')
        storage.set_default(
          'command_history_buffer_size',
          DEFAULT_BUFFER_SIZE)
        storage.set_default('command_history', {})
        storage
      end
    end

    class OpenREPL < Command
      def open_repl(mirror)
        tab = win.new_tab(Redcar::REPL::Tab)
        tab.repl_mirror = mirror
        tab.focus
      end
    end
  end
end