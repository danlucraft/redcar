
module Redcar
  def self.StatusBar
    Redcar::StatusBar
  end
  
  class StatusBar
    
    MAX_LENGTH = 100
    
    def self.statusbar1=(w)
      @@statusbar1 = w
    end
    
    def self.statusbar1
      @@statusbar1
    end
    
    def self.statusbar2=(w)
      @@statusbar2 = w
    end
    
    def self.statusbar2
      @@statusbar2
    end
    
    def self.main=(text)
      cid = @@statusbar1.get_context_id("status1")
      @@statusbar1_time = Time.now
      @@main ||= []
      @@main << text
      @@main = @@main[(MAX_LENGTH - @@main.length)..(@@main.length-1)]
      @@statusbar1.push cid, text
    end
    
    def self.main_time
      @@statusbar1_time ||= Time.now - 1.year
    end
    
    def self.main
      @@main ||= []
      @@main.last
    end
    
    def self.main_history(num)
      @@main ||= []
      @@main[-1..-(num-1)]
    end
    
    def self.main_clear
      cid = @@statusbar1.get_context_id("status1")
      @statusbar1.push cid, ""
    end
    
    def self.sub
      @@sub ||= []
      @@sub.last
    end
    
    def self.sub_time
      @@statusbar2_time ||= Time.now - 1.year
    end
    
    def self.sub=(text)
      cid = @@statusbar2.get_context_id("status2")
      @@statusbar2_time = Time.now
      @@sub ||= []
      @@sub << text
      @@sub = @@sub[(MAX_LENGTH - @@sub.length)..(@@sub.length-1)]
      @@statusbar2.push cid, text
    end
    
    def self.sub_history(num)
      @@sub ||= []
      @@sub[-1..-(num-1)]
    end
    
    def self.sub_clear
      cid = @@statusbar2.get_context_id("status2")
      @statusbar2.push cid, ""
    end
    
    def self.clear_histories
      @@main = []
      @@sub  = []
    end
  end
end
