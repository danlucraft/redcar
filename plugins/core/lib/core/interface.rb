# This module helps API authors to document the interfaces their API requires objects
# to implement.
# 
# Example.
#
# The EditView class allows plugins to register tab handlers. A tab handler must implement
# the "handle" method:
#
#   class MyTabHandler
#     def handle(edit_view)
#     end
#   end
#
# The EditView class wants to check that the object (at least minimally) conforms to the
# tab handler interface, so it defines an 'example' module and mixes in Interface::Abstract.
#
#   class EditView
#     module Handler
#       include Interface::Abstract
#       
#       def handle(edit_view)
#       end
#     end
#
# The Abstract module will not allow this example interface to be mixed in anywhere.
# To verify that any given object conforms to the interface, EditView calls verify_interface!:
#
#     def self.register_tab_handler(tab_handler)
#       EditView::Handler.verify_interface!(tab_handler)
#       @tab_handlers << tab_handler
#     end
#   end
#
# This will raise an error if the instance does not implement all the methods in the example
# interface with the correct aritys.
class Interface
  module Abstract
    def self.included(klass)
      klass.class_eval do
        def self.included(klass)
          raise "#{klass} is trying to mixin #{self}, which is an abstract interface"
        end
        
        def self.verify_interface!(instance)
          Interface.verify!(self, instance)
        end
      end
    end
  end
      
  class BadInterfaceError < StandardError; end
  
  def self.verify(interface, instance)
    interface.instance_methods.all? do |method_name| 
      method = interface.instance_method(method_name)
      instance.respond_to?(method_name) and 
        instance.method(method_name).arity == method.arity
    end
  end
  
  def self.verify!(interface, instance)
    interface.instance_methods.each do |method_name| 
      method = interface.instance_method(method_name)
      unless instance.respond_to?(method_name)
        raise BadInterfaceError, "expected #{instance.inspect} to implement #{interface}, but was missing :#{method_name}"
      end
      unless instance.method(method_name).arity == method.arity
        raise BadInterfaceError, "expected #{instance.inspect} to implement #{interface}, but :#{method_name} arity was not #{method.arity}"
      end
    end
    true
  end
end
