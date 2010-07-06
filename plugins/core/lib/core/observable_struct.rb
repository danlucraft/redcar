
# Adds Redcar::Observable to Struct. e.g:
#
#   irb> Customer = ObservableStruct.new(:name, :address) 
#   => Customer
#   irb> customer = Customer.new("Dave", "123 Main")
#   => #<Customer name="Dave", address="123 Main">
#   irb> customer.add_listener(:changed_name) { |new_name| puts "the new name is: #{new_name}" }
#   => #<Proc:0x65f4cdd2@(irb):203>
#   irb> customer.name = "Dan"
#   the new name is Dan
#   => #<Customer name="Dan", address="123 Main">
class ObservableStruct
  def self.new(*args)
    klass = Struct.new(*args)
    klass.send(:include, Redcar::Observable)
    if args.first.is_a?(String)
      accessors = args[1..-1]
    else
      accessors = args
    end
    accessors.each do |accessor|
      klass.class_eval %Q{
        alias_method :set_#{accessor}, :#{accessor}=
        def #{accessor}=(val)
          notify_listeners(:changed_#{accessor}, val) do
            self.set_#{accessor}(val)
          end
        end
      }
    end
    klass
  end
end