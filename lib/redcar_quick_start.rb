require 'socket'

module Redcar
  def self.try_to_load_via_drb
    return if ARGV.find{|arg| arg == "--multiple-instance" || arg == '--help' || arg == '-h'}
    begin
      begin
        TCPSocket.new('127.0.0.1', DRB_PORT).close
      rescue Errno::ECONNREFUSED 
        # no other instance is currently running...
        return
      end
      puts 'attempting to start via running instance' if $VERBOSE
      
      require 'drb' # late require to avoid loadup time
      drb = DRbObject.new(nil, "druby://127.0.0.1:#{DRB_PORT}")
      
      if ARGV.any?
        ARGV.each do |arg|
          next if arg[0..0] == "-"
          if drb.open_item_drb(File.expand_path(arg)) != 'ok'
            return
          end        
        end
      else
       return unless drb.open_item_drb('just_bring_to_front')
      end
      puts 'Success' if $VERBOSE
      true
    rescue Exception => e
      puts e.class.to_s + ": " + e.message
      puts e.backtrace
      false
    end
  end
end
