
class Symbol
  def to_title_string
    self.to_s.gsub("_", " ").split(" ").map{|w| w.capitalize}.join(" ")
  end
end

class String
  def to_title_symbol
    self.downcase.gsub(/ |-/, "_").intern
  end
end

class PickyHash < Hash
  def [](id)
    r = super(id)
    unless r
      raise ArgumentError, "no hash pair with key: #{id.inspect}"
    end
    r
  end
end

# note how we use UnboundMethod#bind to ensure 
# that the context of the block is the instance, rather
# than the class.
#
# usage:
# class Foo
#   define_method_bracket :logins do |val|
#     @logins[val]
#   end
# end

# f = Foo.new([1, 2, 3])
# f.logins[1] # => 2

class Module
  def define_method_bracket(name, &code)
    define_method("#{name}_bracketed", &code)
    m = instance_method("#{name}_bracketed")
    remove_method "#{name}_bracketed"

    define_method(name) do ||
        obj = Object.new
      m1 = m.bind(self)
      (class << obj; self; end).module_eval { 
        define_method(:[]) { |x|
          m1[x] 
        } 
      }
      obj
    end
  end
  
  def define_method_bracket_equals(name, &code)
    define_method("#{name}_bracketed", &code)
    m = instance_method("#{name}_bracketed")
    remove_method "#{name}_bracketed"

    define_method(name) do ||
        obj = Object.new
      m1 = m.bind(self)
      (class << obj; self; end).module_eval { 
        define_method(:[]) { |x, v|
          m1[x] = v
        } 
      }
      obj
    end
  end
end

class Hash
  def picky
    ph = PickyHash.new
    self.each do |k, v|
      ph[k] = v
    end
    ph
  end
end

class NilClass
  def copy
    nil
  end
end

class String
  def delete_slice(range)
    s = range.begin
    e = range.end
    s = self.length + s if s < 0
    e = self.length + e if e < 0
    s, e = e, s if s > e
    first = self[0..(s-1)]
    second = self[(e+1)..-1]
    if s == 0
      first = ""
    end
    if e >= self.length-1
      second = ""
    end
    self.replace(first+second)
    self
  end
end

if $0 == __FILE__
  p "01234".delete_slice(1..2) == "034"
  p "01234".delete_slice(0..1) == "234"
  p "01234".delete_slice(0..0) == "1234"
  p "01234".delete_slice(0..4) == ""
  p "01234".delete_slice(4..4) == "0123"
  p "01234".delete_slice(1..-1) == "0"
  p "01234".delete_slice(-1..-1) == "0123"
end
