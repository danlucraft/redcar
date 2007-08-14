
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

class Object
  alias before_dot_const_method_missing method_missing
  def method_missing(sym, *args, &block)
    if sym.to_s =~ /[A-Z][a-z]*/
      begin
        if const = const_get(sym.to_s)
          return const
        end
      rescue NameError
      end
    end
    before_dot_const_method_missing(sym, *args, &block)
  end
  
  def sputs
    Kernel.puts self
    self
  end
  
  def sp
    Kernel.p self
    self
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
          m1.call(x)
        } 
      }
      obj
    end
  end
  
  def define_method_bracket_with_equals(name, blocks)
    define_method("#{name}_get_bracketed", &blocks[:get])
    m_get = instance_method("#{name}_get_bracketed")
    remove_method "#{name}_get_bracketed"

    define_method("#{name}_set_bracketed", &blocks[:set])
    m_set = instance_method("#{name}_set_bracketed")
    remove_method "#{name}_set_bracketed"

    define_method(name) do ||
        obj = Object.new
      m1 = m_get.bind(self)
      m2 = m_set.bind(self)
      (class << obj; self; end).module_eval { 
        define_method(:[]) { |x|
          m1.call(x)
        } 
        define_method(:[]=) { |x, v|
          m2.call(x, v)
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

if $0 == __FILE__
  p "01234".delete_slice(1..2) == "034"
  p "01234".delete_slice(0..1) == "234"
  p "01234".delete_slice(0..0) == "1234"
  p "01234".delete_slice(0..4) == ""
  p "01234".delete_slice(4..4) == "0123"
  p "01234".delete_slice(1..-1) == "0"
  p "01234".delete_slice(-1..-1) == "0123"
end

# Methodphitamine

module Kernel
  protected
  def it() It.new end
  alias its it
end

class It

  undef_method(*(instance_methods - %w*__id__ __send__*))

  def initialize
    @methods = []
  end

  def method_missing(*args, &block)
    @methods << [args, block] unless args == [:respond_to?, :to_proc]
    self
  end

  def to_proc
    lambda do |obj|
      @methods.inject(obj) do |current,(args,block)|
        current.send(*args, &block)
      end
    end
  end
end

if $0.include? "spec"
  describe "Methodphitamine" do
    it 'should work simple' do
      new = (1..10).select &it % 2 == 0
      old = (1..10).select {|i| i % 2 == 0}
      new.should == old
    end

    it 'should work more complex' do
      old = "dan:1\nmithu:2".split.sort_by {|l| l.split(":")[1]}
      new = "dan:1\nmithu:2".split.sort_by &it.split(":")[1]
      new.should == old
    end
    
    it 'should work more complex2' do
      w = [[%w{A B C}, [1, 2, 3]], [%w{D E F}, [1, 2, 3]]]
      old = w.map {|e| e.first.map {|x| x.downcase}}
      new = w.map &its.first.map(&its.downcase)
      new.should == old
    end
  end
end
