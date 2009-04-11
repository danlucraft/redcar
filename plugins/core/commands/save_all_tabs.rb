module Redcar
  class SaveAllTabsCommand < Redcar::TabCommand
    key "Ctrl+Super+S"
    icon :SAVE

    def execute
      win.tabs.each { |tab| tab.save if tab.respond_to?(:save) }
    end
  end
end
