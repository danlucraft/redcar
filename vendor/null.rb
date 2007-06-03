#
# A null object.
#

def null
  null = Object.new
  def null.method_missing(name, *args)
    ct = caller[0]#.split(":").first.split("/")[-2..-1].join("/")
    puts "#{name} sent to null by #{ct}"
  end
  null
end

class Object
  def tap
    yield self
    self
  end
end
  
class Object
  alias fn lambda
end
