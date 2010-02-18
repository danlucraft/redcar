require 'socket'

module Redcar

  # attempt to load via drb if available
  def self.try_to_load_via_drb
    return if ARGV.include?("--multiple-instance")
    port = 9999
    begin
      begin
        TCPSocket.new('127.0.0.1', port).close
      rescue Errno::ECONNREFUSED 
        # no other instance is currently running...
        return
      end
      puts 'attempting to start via running instance'
      require 'drb' # late require to avoid loadup time
      drb = DRbObject.new(nil, "druby://127.0.0.1:#{port}")
      
      if ARGV.any?
        ARGV.each do |arg|
          next if arg.start_with?('--')
          if drb.open_item_drb(File.expand_path(arg)) != 'ok'
            return
          end        
        end
      else
       return unless drb.open_item_drb('just_bring_to_front')
      end
      puts 'Success'
      true
    rescue Exception => e
      puts e.class.to_s + ": " + e.message
      puts e.backtrace
      false
    end
  end
end