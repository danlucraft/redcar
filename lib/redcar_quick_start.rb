require 'socket'
require 'rbconfig'

module Redcar
  DRB_PORTS = {"user" => 10021, "test" => 10022, "development" => 10021}
  DONT_READ_STDIN_ARG = "--ignore-stdin"

  def self.environment
    :user
  end
  
  def self.drb_port
    DRB_PORTS[Redcar.environment.to_s]
  end

  def self.read_stdin
    if not $stdin.tty? and not ARGV.include?(DONT_READ_STDIN_ARG)
      data = ""
      begin
      data = $stdin.read
      rescue Errno::EAGAIN
      #  retry
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
        TCPSocket.new('127.0.0.1', drb_port).close
      rescue Errno::ECONNREFUSED
        # no other instance is currently running...
        return
      end
      puts 'attempting to start via running instance' if $VERBOSE

      require 'drb' # late require to avoid loadup time
      drb = DRbObject.new(nil, "druby://127.0.0.1:#{drb_port}")

      if ARGV.any?
        ARGV.each do |arg|
          if arg =~ /--untitled-file=(.*)/
            path = $1 if File.file?($1)
            untitled = true
          elsif arg !~ /^--/ # not --something
            path = File.expand_path(arg)
            if !File.exist?(path)
              require 'fileutils'
              FileUtils.mkdir_p File.dirname(path)
              FileUtils.touch path
            end
          end
          next unless path
          drb_answer = drb.open_item_drb(path, untitled, ARGV.include?("-w"))
          return unless drb_answer == 'ok'
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

  # Platform symbol
  #
  # @return [:osx/:windows/:linux]
  def self.platform
    case Config::CONFIG["target_os"]
    when /darwin/
      :osx
    when /mswin|mingw/
      :windows
    when /linux/
      :linux
    end
  end

  def self.null_device
    case platform
    when :windows
      'nul'
    else
      '/dev/null'
    end
  end
end
