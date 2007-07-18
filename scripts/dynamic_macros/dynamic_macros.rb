
DYN_MAX = 30

module Redcar
  class TextTab
    #keymap "ctrl g", :repeat
    #keymap "ctrl h", :predict
    
    def repeat
      Redcar.StatusBar.main = "repeat, (hit 'predict' for alternative suggestion)"
      DynamicMacros.repeat(self)
    end
    
    def predict
      DynamicMacros.predict(self)
    end
  end
  
  module DynamicMacros
    def self.predict_seq
      @@seq ||= nil
      if @@seq
        @@length = nil
        @@gap = nil
        return @@seq
      end
      @@length ||= nil
      @@gap ||= nil
      @@history = get_history
      seq, length, gap = self.find_repeated_sequence(@@history, @@length, @@gap)
      if seq
        @@length = length
        @@gap = gap
        seq.reverse!
        @@seq = seq
        if length == seq.length
          c = seq
        else
          c = seq[length..-1]
        end
        c
      else
        nil
      end
    end
    
    def self.get_history
      history = @@tab.command_history
      from = [DYN_MAX, history.length].min
      clean_history = history[-from..-1].reject do |com| 
        com == [:repeat, []] or com == [:predict, []]
      end
      clean_history.reverse!
    end
    
    def self.clear
      @@seq = nil
      @@length = nil
      @@gap = nil
    end
    
    def self.predict(tab)
      @@tab = tab
      @@seq ||= nil
      @@length ||= nil
      @@gap ||= nil
      if @@seq and @@length and @@gap
        results = self.find_repeated_sequence(@@history, @@length, @@gap)
        if results
          seq, length, gap = results
          @@seq = seq.reverse!
          @@length = length
          @@gap = gap
          tab.undo
#           @@to_undo.times { Redcar.keystrokes.issue "BackSpace" }
#           @@to_undo = @@seq[length..-1].length
          seq = @@seq
          tab.instance_eval do
            undoable do
              seq[length..-1].each do |com|
                self.send(com[0], *com[1])
              end
            end
          end
        end
      end
    end
      
    def self.repeat(tab)
      @@tab = tab
      seq = self.predict_seq
      if seq
        #       @@to_undo = seq.length
        tab.instance_eval do
          undoable do
            seq.each do |com|
              self.send(com[0], *com[1])
            end
          end
        end
        obj = self
        Redcar.hook :keystroke do |kb|
          if kb != "control g" and kb != "control h"
            obj.clear
          end
          Redcar.clear_hooks
        end
      else
        Redcar.StatusBar.main = "repeat: no suggestions"
      end
    end
    
    def self.find_repeated_sequence(array, inlength=nil, ingap=nil)
      given_input = (inlength and ingap)
      ingap = 0 unless ingap
      one_iter = (inlength==nil)
      if ingap == 0
        unless given_input
          inlength = (array.length)/2
        end
        inlength.downto(1) do |length|
          a = array[0..(length-1)]
          b = array[(length)..(2*length-1)]
          if a == b and one_iter
            c = array[length..(2*length-1)]
            return c, length, 0
          end
          one_iter = true
        end
      end
      one_iter = false
      inlength = (array.length-1)/2 unless given_input and ingap > 0
      inlength.downto(1) do |length|
        unless given_input
          ingap = 0
        end
        
        ingap.upto(array.length-2*length) do |gap|
          a = array[0..(length-1)]
          b = array[(length+gap)..(2*length+gap-1)]
          if a == b and one_iter
            c = array[length..(2*length+gap-1)]
            return c, length, gap
          end
          one_iter = true
        end
        ingap = 1
      end
      nil
    end
    
    def self.find_repeated_sequences(array)
      seqs = []
      length = nil
      gap = nil
      while result = find_repeated_sequence(array, length, gap)
        seqs << result[0]
        length = result[1]
        gap = result[2]
      end
      seqs
    end
    
#     def self.find_repeated_sequences(array)
#       seqs = []
#       (array.length/2).times do |length|
#         # length is the length of the 'trigger' sequence
#         (array.length-1-2*length).times do |gap|
#           a = array[0..length]
#           b = array[(length+1+gap)..(2*length+1+gap)]
#           if a == b
#             seq = array[(length+1)..(2*length+1+gap)]
#             seqs << [seq, length, b]
#           end
#         end
#       end
#       # sort by the length of the trigger, on the grounds that the more
#       # of the trigger that matches, the greater the likelihood
#       # of this sequence being the correct one.
#       seqs.each { |s| p s.map(&:to_s)}
#       c=seqs.sort_by{|arr| -arr[1]}.map{|arr| arr[0]}
#       c
#     end
  end
end
