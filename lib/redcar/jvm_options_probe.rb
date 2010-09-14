
class JvmOptionsProbe
  def initialize
    @help = `java -help`
  end
  
  def can_use_d32?
    @help.include?("-d32")
  end
  
  def can_use_client?
    @help.include?("-client")
  end
end