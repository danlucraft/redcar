
class Object
  def bus(arg=nil, safe=false)
    if safe
      bits = arg.split("/")[1..-1]
      path = "/"
      bits.length.times do |i|
        if $BUS[path].has_child? bits[i]
          path += "/"+bits[i]
        else
          return nil
        end
      end
      $BUS[arg]
    else
      if arg
        $BUS[arg]
      else
        $BUS
      end
    end
  end
end
