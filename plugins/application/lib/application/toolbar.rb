
module Redcar
  class ToolBar
    include Enumerable
    include Redcar::Model
    
    # Default priority for all toolbar's and items if they aren't explicitly provided
    DEFAULT_PRIORITY = 50
    
    attr_reader :text, :entries, :priority
  
    # A ToolBar will initially have nothing in it.
    def initialize(text=nil, options={})
      @text, @entries, @priority = text || "", [], options[:priority]
    end
  
    # Iterate over each entry, sorted by priority
    def each
      sorted = {:first => [], :last => []}
      entries.each {|e| (sorted[e.priority || ToolBar::DEFAULT_PRIORITY] ||= []) << e}
      
      # Get the nasty Symbols out of the hash so we can sort it
      first = sorted.delete(:first)
      last = sorted.delete(:last)
      
      # Yield up the results
      first.each {|val| yield val }
      sorted.keys.sort.each {|i| sorted[i].each {|val| yield val }}
      last.each {|val| yield val }
    end
  
    # Add a Redcar::ToolItem or a Redcar::ToolBar
    def <<(entry)
      entries << entry
      self
    end
  
    # Number of entries in the toolbar
    def length
      entries.length
    end
    
    def entry(text)
      detect {|e| e.text == text }
    end
    
    # Append items using the same syntax as ToolBar::Builder
    def build(&block)
      ToolBar::Builder.new(self, &block)
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
    
    # Merge two ToolBar trees together. Modifies this ToolBar.
    #
    # @param [ToolBar] another ToolBar
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
  end
end
