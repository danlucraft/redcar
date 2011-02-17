
module Redcar
  class Menu
    include Enumerable
    include Redcar::Model

    # Default priority for all menu's and items if they aren't explicitly provided
    DEFAULT_PRIORITY = 50

    # Default mnemonic values for primary menus
    MNEMONICS = {
      "File"    => "&File",
      "Edit"    => "&Edit",
      "Project" => "&Project",
      "Debug"   => "&Debug",
      "View"    => "&View",
      "Plugins" => "P&lugins",
      "Bundles" => "&Bundles",
      "Help"    => "&Help"
    }

    attr_reader :text, :entries, :priority

    # A Menu will initially have nothing in it.
    def initialize(text=nil, options={})
      @text, @entries, @priority = Menu.parse(text), [], options[:priority]
    end

    # Iterate over each entry, sorted by priority
    def each
      sorted = {:first => [], :last => []}
      entries.each {|e| (sorted[e.priority || Menu::DEFAULT_PRIORITY] ||= []) << e}

      # Get the nasty Symbols out of the hash so we can sort it
      first = sorted.delete(:first)
      last = sorted.delete(:last)

      # Yield up the results
      first.each {|val| yield val }
      sorted.keys.sort.each {|i| sorted[i].each {|val| yield val }}
      last.each {|val| yield val }
    end

    # Add a Redcar::MenuItem or a Redcar::Menu
    def <<(entry)
      entries << entry
      self
    end

    # Number of entries in the menu
    def length
      entries.length
    end

    # Fetch the sub_menu with the given name
    #
    # @param [String]
    # @return [Menu]
    def sub_menu(text)
      detect {|e| e.text == text and e.is_a?(Menu) }
    end

    def entry(text)
      detect {|e| e.text == text }
    end

    # Append items and sub_menus using the same syntax as Menu::Builder
    def build(&block)
      Menu::Builder.new(self, &block)
    end

    def ==(other)
      return false unless length == other.length
      return false unless text == other.text
      entries.zip(other.entries) do |here, there|
        return false unless here.class == there.class and here == there
      end
      true
    end

    def is_unique?
      false
    end

    def lazy_text?
      false
    end

    # Merge two Menu trees together. Modifies this Menu.
    #
    # @param [Menu] another Menu
    def merge(other)
      @priority = @priority || other.priority
      other.entries.each do |other_entry|
        if here = entry(other_entry.text) and not other_entry.is_unique?
          if here.class == other_entry.class
            here.merge(other_entry)
          else
            entries[entries.index(here)] = other_entry
          end
        else
          self << other_entry
        end
      end
    end

    # Get menu text from a string, adding mnemonics where applicable
    def self.parse(menu_text)
      menu_text = "" unless menu_text
      if Redcar.platform != :osx and mnemonic = MNEMONICS[menu_text]
        mnemonic
      else
        menu_text
      end
    end
  end
end
