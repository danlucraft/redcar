
def Instrument(name, value)
  Instruments.instrument(name, value)
end

module Instruments
  
  def self.instrument(name, value)
    @@instruments ||= {}
    (@@instruments[name] ||= []) << value
  end
  
  def self.report(name)
    arr = @@instruments[name]
    if arr and !arr.empty?
      puts "name: #{name}"
      puts "  num:  #{arr.length}"
      puts "  min:  #{arr.min}"
      puts "  max:  #{arr.max}"
      puts "  mean: #{arr.inject(0.0){|m,o| m+=o}.div(arr.length)}"
    else
      puts "no instrumentation with name: #{name}"
    end
  end
end  

