
def Instrument(name, value)
  Instrument.instrument(name, value)
end

module Instrument
  def self.instrument(name, value)
    @@instruments ||= {}
    (@@instruments[name] ||= []) << value
  end
  
  def self.report(name)
    arr = @@instruments[name]
    if arr and !arr.empty?
      puts "name: #{name}\n  num:  #{arr.length},  min:  #{arr.min}, "+
        "max:  #{arr.max}, mean: "+
        "#{arr.inject(0.0){|m,o| m+=(o.to_f)}/arr.length.to_f},"+
        " median: #{arr.sort[arr.length/2]}"
    else
      puts "no instrumentation with name: #{name}"
    end
  end
end  

