
class Object
  def bus(arg=nil)
    if arg
      $BUS[arg]
    else
      $BUS
    end
  end
end
