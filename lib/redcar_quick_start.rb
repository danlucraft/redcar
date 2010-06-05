require 'socket'

module Redcar
  DRB_PORT = 10021
  DONT_READ_STDIN_ARG = "--ignore-stdin"
  
  def self.read_stdin
    if not $stdin.tty? and not ARGV.include?(DONT_READ_STDIN_ARG)
      data = ""
      begin
        chunk = $stdin.read_nonblock(1024)
        data << chunk
        while chunk
          chunk = $stdin.read_nonblock(1024)
          data << chunk
        end
      rescue Errno::EAGAIN
        retry
      rescue EOFError
      end
      
      if data.size > 0
        require 'tmpdir'
        file = File.join(Dir.tmpdir, "tmp#{$$}.txt")
        File.open(file, 'w') {|f| f.write data}
        ARGV.unshift "--untitled-file=#{file}", DONT_READ_STDIN_ARG
      end
    end
  end
  
  def self.try_to_load_via_drb
    return if ARGV.find {|arg| arg == "--multiple-instance" || arg == '--help' || arg == '-h'}
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
          if File.file?(arg) or File.directory?(arg)
            if drb.open_item_drb(File.expand_path(arg)) != 'ok'
              return
            end
          end
          if arg =~ /--untitled-file=(.*)/
            path = $1
            if File.file?(path)
              if drb.open_item_untitled(File.expand_path(path)) != 'ok'
                return
              end
            end
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