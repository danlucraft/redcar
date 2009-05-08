
# there seems to be some kind of compatibility problem with 
# Ruby-DBus on Jaunty. Needs fixing properly.

module DBus
  class Connection
    # Process a message _m_ based on its type.
    # method call:: FIXME...
    # method call return value:: FIXME...
    # signal:: FIXME...
    # error:: FIXME...
    def process(m)
      case m.message_type
      when Message::ERROR, Message::METHOD_RETURN
        raise InvalidPacketException if m.reply_serial == nil
        mcs = @method_call_replies[m.reply_serial]
        if not mcs
          puts "no return code for #{mcs.inspect} (#{m.inspect})" if $DEBUG
        else
          if m.message_type == Message::ERROR
            mcs.call(Error.new(m))
          else
            mcs.call(m)
          end
          @method_call_replies.delete(m.reply_serial)
          @method_call_msgs.delete(m.reply_serial)
        end
      when DBus::Message::METHOD_CALL
        if m.path == "/org/freedesktop/DBus"
          puts "Got method call on /org/freedesktop/DBus" if $DEBUG
        end
        # handle introspectable as an exception:
        if m.interface == "org.freedesktop.DBus.Introspectable" and
          m.member == "Introspect"
          reply = Message.new(Message::METHOD_RETURN).reply_to(m)
          reply.sender = @unique_name
          node = @service.get_node(m.path)
          raise NotImplementedError if not node
          reply.sender = @unique_name
          reply.add_param(Type::STRING, @service.get_node(m.path).to_xml)
          send(reply.marshall)
        else
          # DBL: added this to hack around DBus fail on jaunty
          if @service.nil?
            return
          end
          node = @service.get_node(m.path)
          return if node.nil?
          obj = node.object
          return if obj.nil?
          obj.dispatch(m) if obj
        end
      when DBus::Message::SIGNAL
        @signal_matchrules.each do |elem|
          mr, slot = elem
          if mr.match(m)
            slot.call(m)
            return
          end
        end
      else
        puts "Unknown message type: #{m.message_type}" if $DEBUG
      end
    end
  end
end
