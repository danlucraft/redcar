# Purpose: FreeBASE Databus. A publish/subscribe hierarchical system.
#    
# $Id: databus.rb,v 1.6 2006/06/04 05:50:00 curthibbs Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
#               based on an original design by Curt Hibbs <curt@hibbs.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
# 
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'thread'

module FreeBASE

  ##
  # The DataBus class is used to manage a publish/subscribe system
  # Usage::
  #
  #   class SubscriptionTest
  #     def databus_notify(event, slot)
  #       puts "Tester Class got #{slot.data}"
  #     end
  #   end
  #
  #   databus = FreeBASE::DataBus.new
  #   st = SubscriptionTest.new
  #   databus["/foo/bar"].subscribe(st)
  #   id = databus["/foo/bar"].subscribe {|event, slot| puts "Block got #{slot.data}" }
  #   databus["/foo/bar"].data = "data :-)" #=> publishes data
  #   databus["/foo/bar"].unsubscribe(id)
  #   databus["/foo/bar"].unsubscribe(st)
  #   databus["/foo/bar/int"].validate("Does not implement to_i") { | value | value.respond_to? "to_i" }
  #   databus["/foo/bar/int"].data = Hash.new  #=> raises Does not implement to_i
  #
  #   stack, data, proc, queue
  #
  class DataBus
  
    SEPARATOR = 47; # 47 is ASCII for /
    
    SUBSCRIBER = 0
    EVENT = 1
    SLOT = 2
    
    # True to enable validating values in slots, default=true
    attr_accessor :validation_enabled

    # True if notify method propagates to parent.notify, default=true
    attr_accessor :propagate_notifications
    
    # The root of this DataBus
    attr_reader :root
    
    # The parent slot
    attr_reader :parent
    
    attr_reader :state
    
    attr_reader :notification_thread
    
    ##
    # Constructs a DataBus
    #
    def initialize
      @root = Slot.new("", nil, self)
      @notification_queue = []
      @idCount = 0
      @validation_enabled = true
      @propagate_notifications = true
      #start
    end
    
    ##
    # Place a notification event into the queue to be delivered asynchronously
    #
    # to:: [Proc | #databus_notify] The object to deliver the event to
    # event:: [Symbol] The event symbol
    # slot:: [DataBus::Slot] The slot that the event occurred at
    #
    def queue_notification(to, event, slot)
      @notification_queue << [to, event, slot]
      @notification_thread.wakeup if @notification_thread.stop?
    end
    
    ##
    # Starts the asynchronous notification queue
    #
    def start
      @notification_thread = Thread.new {
        loop do
          while notification = @notification_queue.shift
            if notification[SUBSCRIBER].kind_of? Proc
              notification[SUBSCRIBER].call(notification[EVENT], notification[SLOT])
            else
              notification[SUBSCRIBER].databus_notify(notification[EVENT], notification[SLOT])
            end
          end
          sleep unless @notification_queue.size > 0
        end
      }
    end
    
    ##
    # Navigates to a path (relative) to the root
    #
    # path:: [String] The path (i.e. /foo/bar or foo/bar)
    # return:: [FreeBASE::DataBus::Slot] The new or existing slot
    # see:: FreeBASE::DataBus::Slot#[]
    #
    def [](path)
      @root[path]
    end
    
    ##
    # Incremented subscriber id counter
    #
    # return:: [Integer] unique id (incremented)
    #
    def idCount
      @idCount = @idCount + 1
    end
    
    ##
    # The LinkSlot class represents a slot that is a logical link
    # to another slot in the databus
    #
    class LinkSlot
      attr_reader :path, :parent, :name
      
      ##
      # Constructs a new link slot with the given name and parent
      # linked to the supplied slot
      #
      # name:: [String] the name of this link slot
      # parent:: [FreeBASE::DataBus::Slot] The parent of this slot
      # link:: [FreeBASE::DataBus::Slot] The slot to link to
      #
      def initialize(name, parent, link)
        @name = name
        @parent = parent
        @path = parent.nil? ? "/" : "#{parent.path}#{name}/"
        @link = link
      end
      
      ##
      # Unlinks this slot from the parent
      #
      def unlink
        @parent.unlink(self)
      end
      
      ##
      # Unlinks if pruning link slot, otherwise forwards to linked slot
      #
      # name:: [String=nil] The name of the slot to unlink
      #
      def prune(name=nil)
        unlink unless name
        @link.prune(name) if name
      end
      
      ##
      # Returns if this slot is a link slot
      #
      # return:: [Boolean] True for all LinkSlot instances
      #
      def is_link_slot?
        return true
      end
      
      ##
      # Forward all unhandled calls to the linked slot
      #
      def method_missing(meth, *attrs, &block)
        @link.send(meth, *attrs, &block)
      end
    end
    
    ##
    # The Slot class represents a subscribe and/or publish node
    #
    class Slot
      DATA  = "data_slot"
      QUEUE = "queue_slot"
      STACK = "stack_slot"
      PROC  = "proc_slot"
      MAP  = "map_slot"
      
      # True if notify method propagates to parent.notify, default=true
      attr_accessor :propagate_notifications
      
      attr_reader :path, :parent, :name, :attrs
      
      ##
      # Creates a new Slot
      # 
      # name:: [String] The name of the slot
      # parent:: [Slot | Databus] The parent slot (or nil if root
      # databus:: [Databus] The databus instance
      #
      def initialize(name, parent, databus)
        @name = name
        @parent = parent
        @path = parent.nil? ? "/" : "#{parent.path}#{name}/"
        @databus = databus
        @slots = Hash.new
        @subscribers = Hash.new
        @propagate_notifications = true
        notify(:notify_slot_add)
      end
      
      ##
      # Returns if this slot is the root slot
      #
      # return:: [Boolean] true if this slot is root
      #
      def root?
        return true if self==@databus.root
      end
      
      ##
      # Sets this slots active manager
      #
      # manager:: [Object] The object to manager this slot
      # raise:: [RuntimeException] If this slot is alread managed
      #
      def manager=(manager)
        raise "Slot #{@path} already has an active manager: #{@manager}" if @manager
        @manager = manager
        notify(:notify_slot_managed)
      end
      
      ##
      # Returns the manager of this slot (or its parent manager if 
      # this slot does not have a manager
      #
      # return:: [Object] The manager of this slot or nil
      #
      def manager
        return @manager if @manager or root?
        return @parent.manager
      end
      
      ##
      # Determines if this slot has an active manager registered
      # on it.  This does not access the parent's manager if one 
      # is not set on this slot (as does the _manager method.
      #
      # return:: [Boolean] True if this slot has an active manager
      #
      def managed?
        return @manager ? true : false
      end
      
      ##
      # Checks if this slot has a child slot of the given name
      #
      # name:: [String] The name of the child slot
      # return:: [Boolean] True if child slot exists, otherwise false
      #
      def has_child?(name=nil)
        unless name
          return true if @slots.size > 0
          return false
        end
	return @slots.has_key?(name)
      end
      
      ##
      # Navigates to a path (relative) to the current object (with DataBus as root)
      #
      # path:: [String] The path (i.e. /foo/bar or foo/bar)
      # return:: [FreeBASE::DataBus::Slot] The new or existing slot
      #
      def [](path)
        path = path.split("/") if path.kind_of? String
        while path.first == "." # ignore single dot ./foo
          path.shift
        end
        subslot = path.shift
        unless root?
          return @databus.root[path] if subslot == "" # started at root /foo
          return parent[path] if subslot==".." # parent ../foo
        end
        while subslot=="" # get rid of multi-slashes ///foo
          subslot = path.shift
        end
        return self unless subslot # path now empty...return self
        unless (child = @slots[subslot]) # is child a defined ?
          child = @slots[subslot]= Slot.new(subslot, self, @databus) # build new one
        end
        while path.first==""  # get rid of multi-slashes foo///bar
          path.shift
        end
        return child if path.empty?
        return child[path]
      end
      
      ##
      # Prunes (removes) this slot (and all child slots)
      #
      # name:: [String=nil] The name of the child slot (nil == current slot)
      #   notification: :notify_slot_prune
      #
      def prune(name=nil)
        if name and @slots[name]
          @slots[name].notify(:notify_slot_prune)
          @slots.delete(name)
          return
        end
        raise "Cannot prune root slot" if root?
        @slots.values.each {|slot| slot.prune}
        @parent.prune(@name)
      end
      
      ##
      # Iterates over the sub-slots and link slots
      #
      # recurse:: [Boolean=false] if true, recurses all child slots
      # yeild:: [FreeBASE::DataBus::Slot] The child slot
      #
      def each_slot(recurse=false, &block)
        return unless block_given?
        @slots.keys.sort.each do |name|
          slot = @slots[name]
          yield slot
          slot.each_slot(recurse, &block) if recurse
        end
      end
      
      ##
      # Links a child slot name to another slot in the databus
      #
      # child_name:: [String] The name of the child
      # destination:: [String | FreeBASE::DataBus::Slot] The destination of the link
      #
      def link(child_name, destination)
        destination = self[destination] if destination.kind_of? String
        raise "Can only link to a DataBus::Slot" unless destination.kind_of? Slot
        child = LinkSlot.new(child_name, self, destination)
        @slots[child_name] = child
        notify(:notify_slot_link, child)
        child
      end
      
      ##
      # Unlinks a child slot name to another slot in the databus
      #
      # child:: [String] The name of the child
      #
      def unlink(child)
        return unless child
        child = child.name unless child.kind_of? String
        child = @slots.delete(child)
        notify(:notify_slot_unlink, child) if child
      end
      
      ##
      # Returns if this slot is a link slot
      #
      # return:: [Boolean] True is the slot is a link
      #
      def is_link_slot?
        return false
      end
      
      ##
      # Make the slot a Data slot and set the value of the data.
      #   notification :notify_data_set
      #
      # object:: [Object] The object to store in the slot
      # raise:: [RuntimeException] If there is a validator and it fails to validate the object
      # raise:: [RuntimeException] If this slot is not a Data slot
      #
      def data=(object)
        check_type(DATA)
        validate(object)
        @data = object
        notify(:notify_data_set)
      end
      
      ##
      # Retrieves the value of the data object if this is a Data slot
      #
      # return:: [Object] The object stored in the slot
      # raise:: [RuntimeException] If this slot is not a Data slot
      #
      def data
        check_type(DATA)
        return @data
      end
      alias_method :value, :data
      
      ##
      # Checks is this is a Data slot
      #
      # return:: [Boolean] true if this is a Data slot
      #
      def is_data_slot?
        return @type==DATA
      end
      
      ##
      # calls queue.join if this is a queue slot
      #
      def join(object)
        return self.queue.join(object)
      end
      
      ##
      # calls queue.join if this is a queue slot
      #
      def <<(object)
        return self.queue << object
      end
      
      ##
      # calls queue.leave is this is a queue slot
      #
      def leave
        return self.queue.leave
      end
      
      ##
      # calls stack.push if this is a stack slot
      #
      def push(object)
        return self.stack.push(object)
      end
      
      ##
      # calls stack.pop if this is a stack slot
      #
      def pop
        return self.stack.pop
      end
      
      ##
      # calls map.put if this is a map slot
      #
      def put(key, value)
        return self.map.put(key,value)
      end
      
      ##
      # calls map.get if this is a map slot
      #
      def get(key)
        return self.map.get(key)
      end
      
      ##
      # removes a key if this is a map slot
      #
      def remove(key)
        return self.map.remove
      end
      
      ##
      # Clears the stack or queue or map depending on the slot type
      #
      def clear
        return self.queue.clear if is_queue_slot?
        return self.stack.clear if is_stack_slot?
        return self.map.clear if is_map_slot?
      end
      
      ##
      # Return the number of objects in the stack or queue
      #
      # return:: [Integer] The number of objects
      #
      def count
        return self.queue.count if is_queue_slot?
        return self.stack.count if is_stack_slot?
        return self.map.count if is_map_slot?
      end
      
      ##
      # Retrieves the Queue object if this is a Queue slot
      #
      # return:: [FreeBASE::DataBus::Queue] The queue object of this slot
      # raise:: [RuntimeException] If this slot is not a Queue slot
      #
      def queue
        check_type(QUEUE)
        @queue = Queue.new(self) unless @queue
        return @queue
      end
      
      ##
      # Checks if this is a Queue slot
      #
      # return:: [Boolean] true if this is a Queue slot
      #
      def is_queue_slot?
        return @type==QUEUE
      end
      
      ##
      # Retrieves the Stack object if this is a Stack slot
      #
      # return:: [FreeBASE::DataBus::Stack] The Stack object of this slot
      # raise:: [RuntimeException] If this slot is not a Stack slot
      #
      def stack
        check_type(STACK)
        @stack = Stack.new(self) unless @stack
        return @stack
      end
      
      ##
      # Checks if this is a Stack slot
      #
      # return:: [Boolean] true if this is a Stack slot
      #
      def is_stack_slot?
        return @type==STACK
      end
      
      ##
      # Retrieves the ProcWrapper object if this is a queue slot
      #
      # return:: [FreeBASE::DataBus::ProcWrapper] The ProcWrapper object of this Proc slot
      # raise:: [RuntimeException] If this slot is not a Proc slot
      #
      def proc
        check_type(PROC)
        @proc = ProcWrapper.new(self) unless @proc
        return @proc
      end
      
      ##
      # Checks if this is a Proc slot
      #
      # return:: [Boolean] true if this is a Proc slot
      #
      def is_proc_slot?
        return @type==PROC
      end
      
      ##
      # calls proc.set_proc if this is a proc slot
      #
      def set_proc(proc=nil, &block)
        self.proc.set_proc(proc, &block)
      end
      
      ##
      # calls proc.call if this is a proc slot (invoke is an alias)
      #
      def call(*args, &block)
        return self.proc.call(*args, &block)
      end
      alias_method :invoke, :call
      
      ##
      # Retrieves the Map object if this is a hash slot
      #
      # return:: [FreeBASE::DataBus::Map] The HashWrapper object of this Hash slot
      # raise:: [RuntimeException] If this slot is not a Hash slot
      #
      def map
        check_type(MAP)
        @map = Map.new(self) unless @map
        return @map
      end
      
      ##
      # Checks if this is a map slot
      #
      # return:: [Boolean] true if this is a map slot
      #
      def is_map_slot?
        return @type==MAP
      end
      
      ##
      # Checks to see if the type of slot is as specified.  If the type is not defined, the 
      # type is set to the supplied type.
      #
      # type:: [String] The type of slot
      # raise:: [RuntimeException] If the slot is of a different type that what is supplied
      #
      def check_type(type)
        return if @type == type
        raise "Slot #{path} cannot be set as a #{type} because its already a #{@type}" if @type 
        @type = type
      end
      
      private :check_type
      
      ##
      # Sends out a notification to subscribers of this slot.  If this slot
      # has a parent, the notification is propagated to the parent's notify method
      # until the root slot is reached.
      #
      # event:: [Symbol] The event (:notify_obj_action)
      # slot:: [Slot=self] The slot that has the action on it
      #
      def notify(event, slot = self)
        if @subscribers.size > 0
          @subscribers.each_value do |subscriber|
            #@databus.queue_notification(subscriber, event, slot)
            if subscriber.kind_of? Proc
              subscriber.call(event, slot)
            else
              subscriber.databus_notify(event, slot)
            end
          end
        end
        @parent.notify(event, slot) if @propagate_notifications && @databus.propagate_notifications && @parent
      end
      
      ##
      # Returns the subscribers to this slot (as a hash).
      #
      def subscribers
        return @subscribers
      end
      
      ##
      # If a validator is set on this slot, it is called with the 
      # data object
      #
      # object:: [Object] The object to validate against
      # raise:: [RuntimeException] If validator fails
      #
      def validate(object)
        if @databus.validation_enabled and @validator
          raise@validatorError unless @validator.call(object)
        end
      end
      
      ##
      # The Subscription class is used to hold the slot so 
      # that one can cancel with the object.
      #
      # subscription = @databus['slot'].subscribe { |event, slot| ... }
      # subscription.cancel
      #
      class Subscription
        def initialize(slot)
          @slot = slot
        end
        
        ##
        # Cancel this subscription
        #
        def cancel
          @slot.unsubscribe(self)
        end
      end
      
      ##
      # Subscribe to this slot
      #
      # subscriber:: [Object_databus_notify] The object to process the slot (response w/databus_notify(message, slot)
      # &block:: [Block |message, slot|] The block to process the slot
      # return:: [Object] The subscription ID (used for unsubscribe)
      #
      def subscribe(subscriber=nil, &block)
        if subscriber
          unless subscriber.respond_to?("databus_notify")
            raise "Subscribers must impliment the databus_notify method" 
          end
          @subscribers[subscriber] = subscriber
          return subscriber
        else
          subscription = Subscription.new(self)
          @subscribers[subscription] = Proc.new(&block)
          return subscription
        end
      end
      
      ##
      # Unsubscribes to this slot
      #
      # subscriber:: [Object] The id returned from subscribe
      #
      def unsubscribe(subscriber)
        @subscribers.delete(subscriber)
      end
      
      ##
      # Dumps (puts) the subscriber list
      #
      def dump(array = nil)
        if array
          first = false
        else
          first = true
          array = []
        end
        array << "Slot #{@path} [type='#{@type}', data='#{@data}', manager='#{@manager.class}']" if @type
        @slots.each_value {|slot| slot.dump(array)}
        array.each {|slot| puts slot} if first
      end
      
      ##
      # Sets the validator for this slot
      #
      # validatorError:: [String=""] The error string to display if failure occurs
      # &block:: [Block |object|] The block to process the published object.  Must return true if object is valid.
      #
      def validate_with(validatorError="", &block)
        @validator = block
        @validatorError = "Object published into #{@path} did not pass validator: #{validatorError}"
      end
      
      ##
      # Overrides method_missing to be able to set attributes using the following
      # syntax:
      # get:: slot.attr_<name> to get an attribute vulue
      # set:: slot.attr_<name>=value to set and attribute value
      #
      def method_missing(methId, *args, &block)
        tag = methId.id2name
        if tag[0..4]=="attr_"
          @attrs ||= {}
          if tag[-1]==61 # 'attr_???='
            attrname = tag[5..-2]
            case attrname
            when "parent", "name", "path"
              raise "Attribute set by constructor"
            else
              @attrs[attrname] = args[0]
              notify(:notify_attribute_set, self)
            end
            return
          else
            attrname = tag[5..-1]
            case attrname
            when "parent"
              return @parent
            when "name"
              return @name
            when "path"
              return @path
            else
              return @attrs[attrname]
            end
          end
        end
        super
      end

    end
    
    ##
    # The Queue class represents a FIFO list for Slots that may need 
    # to manage such data (such as User Interface event propagation).
    #
    class Queue
      
      ##
      # Create the Queue object
      #
      # slot:: [FreeBASE::DataBus::Slot] The slot this queue belongs to.
      #
      def initialize(slot)
        @slot = slot
        @queue = []
      end
      
      ##
      # Have the object join the queue
      #   notification :notify_queue_join
      # 
      # object:: [Object] The object to place in the queue
      #
      def join(object)
        @slot.validate(object)
        @queue << object
        @slot.notify(:notify_queue_join)
      end
      
      ##
      # Same as _join(object)
      #
      def <<(object)
        join(object)
      end
      
      ##
      # Have the first object leave the queue
      #   notification :notify_queue_leave
      #
      # return:: [Object] The first object in the queue or nil
      #
      def leave
        result = @queue.shift
        @slot.notify(:notify_queue_leave)
        return result
      end
      
      ##
      # Return the number of objects in the stack
      #
      # return:: [Integer] The number of objects
      #
      def count
        return @queue.size
      end

      ##
      # Clear all objects from the queue
      #   notification :notify_queue_clear
      #
      def clear
        @queue.clear
        @slot.notify(:notify_queue_clear)
      end

      ##
      # Return a given element in the queue. Leave it in place
      #   notification :none
      #   return: the value of the element at index
      def [] (index)
        @queue[index]
      end
      
    end
    
    ##
    # The Stack class represents a LIFO list for Slots that may need 
    # to manage such data.
    #
    class Stack
      
      ##
      # Create the Stack object
      #
      # slot:: [FreeBASE::DataBus::Slot] The slot this queue belongs to.
      #
      def initialize(slot)
        @slot = slot
        @stack = []
      end
      
      ##
      # Push an object onto the stack.
      #   notification :notify_stack_push
      #
      # object:: [Object] The object to push on the stack
      #
      def push(object)
        @slot.validate(object)
        @stack.push object
        @slot.notify(:notify_stack_push)
      end
      
      ##
      # Pop an object off the stack.
      #   notification :notify_stack_pop
      #
      # return:: [Object] The object to popped from the stack
      #
      def pop
        result = @stack.pop
        @slot.notify(:notify_stack_pop)
        return result
      end
      
      ##
      # Return the number of objects in the stack
      #
      # return:: [Integer] The number of objects
      #
      def count
        return @stack.size
      end
      
      ##
      # Clear all objects from the stack
      #   notification :notify_stack_clear
      #
      def clear
        @stack.clear
      end

      ##
      # Return a given element in the stack. Leave it in place
      #   notification :none
      #   return: the value of the element at index
      def [] (index)
        @queue[index]
      end
      
    end
    
    ##
    # The ProcWrapper holds the Proc object for the Proc slot
    #
    # Usage::
    #  p = ProcWrapper.new(self)
    #  p.set {|p1, p2| puts p1,p2}
    #  p.call("one", "two") #=> "one"\n"two"
    #
    class ProcWrapper

      ##
      # Create the ProcWrapper object
      #
      # slot:: [FreeBASE::DataBus::Slot] The slot this proc wrapper belongs to.
      #
      def initialize(slot)
        @slot = slot
      end
      
      ##
      # Sets the proc
      #
      # proc:: [Proc = nil] The (optional) Proc to store
      # &block:: [Block] The block to store
      #
      def set_proc(proc=nil, &block)
        block = proc if proc
        @proc = block
        @slot.notify(:notify_proc_set)
      end
      
      ##
      # Gets the proc
      #
      # return:: [Proc] The proc stored in this slot
      #
      def get_proc
        return @proc
      end
      
      ##
      # Calls the stored proc.
      #   nofication :notify_proc_call
      #
      # *args:: [*Array] The calling param array
      # return:: [Object] The result of the proc
      # raise:: [RuntimeException] If validator is enabled and the supplied args fail validation
      #
      def call(*args)
        @slot.validate(args)
        result = nil
        result = @proc.call(*args) if @proc
        @slot.notify(:notify_proc_call)
        return result
      end
    end

    ##
    # The Map holds the Hash object for the Hash slot
    #
    # Usage::
    #  p = HashWrapper.new(self)
    #  p.put(key, value)
    #  p.get(key) #=> value
    #
    class Map
      ##
      # Create the Map object
      #
      # slot:: [FreeBASE::DataBus::Slot] The slot this proc wrapper belongs to.
      #
      def initialize(slot)
        @slot = slot
        @map = {}
      end
      
      ##
      # Sets the hash
      #
      # hash:: [Hash] The Hash to store
      #
      def map=(hash)
        @map=hash
        @slot.notify(:notify_map_set)
      end
      
      ##
      # Clears the hash
      #
      def clear()
        @map = {}
        @slot.notify(:notify_map_cleared)
      end
      
      ##
      # Removes an item from the hash
      #
      # key:: [key] The key to remove
      #
      def remove(key)
        @map.delete(key)
        @slot.notify(:notify_map_remove)
      end
      
      ##
      # Gets the value
      #
      # key:: [Object] The key
      # return:: [Object] The value of the specified key
      #
      def get(key)
        return @map[key]
      end
      
      ##
      # Sets the value of the supplied key
      #
      # key:: [Object] The key
      # value:: [Object] The value
      #
      def put(key, value)
        @map[key]=value
        @slot.notify(:notify_map_put)
      end
      
      ##
      # Returns if the map slot contains the given key
      # 
      # key:: [Object] The key
      # return:: [Boolean] true if the map has the key, otherwise false
      #
      def has_key?(key)
        return @map.has_key?(key)
      end
      
      ##
      # Return the number of objects in the hash
      #
      # return:: [Integer] The number of objects
      #
      def count
        return @map.size
      end

    end
    
    ##
    # The Adapter is a helper class that allows for connecting slot
    # values together (in a Thread-safe way) so that changes to
    # one (or more) slots would result in automatic updates to
    # other slots
    #
    class Adapter
    
      ##
      # Construct an Adapter object and subscribes to the supplied slots.
      #
      # slots:: [Array of FreeBASE::DataBus::Slot] The slots that the supplied block needs to manage
      # &block:: [Block | msg, slot |] The block to process the slot changes
      #
      def initialize(slots, &block)
        block = proc if proc
        slots.each {|slot| slot.subscribe(self)}
        @proc = block
        @thread_queue = []
      end
      
      ##
      # Called from databus when slots are updated.  This method 
      # queues calling threads to ensure only a single thread updating
      # at the same time.
      #
      # msg:: [Symbol] the message symbol
      # slot:: [FreeBASE::DataBus::Slot] the slot that was updated
      #
      def databus_notify(msg, slot)
        return if @current_thread == Thread.current
        if @current_thread
          @thread_queue << Thread.current
          Thread.current.stop
        end
        @current_thread = Thread.current
        @proc.call(msg, slot)
        @current_thread = nil
        @thread_queue.shift.wake if @thread_queue.size>0
      end
    end
    
    
  end
end
 
