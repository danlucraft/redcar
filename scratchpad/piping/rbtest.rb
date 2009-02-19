#!/usr/bin/env ruby

text = <<TXT
Foo
Barand
BazBazBaz
Quxand
TXT

require 'rubygems'
require 'open4'
ENV['RUBYLIB'] = "/home/dan/projects/textmate/Support/lib"
status = Open4.popen4("/bin/bash scratchpad/shtest.sh") do |pid, stdin, stdout, stderr|
  stdin.write(text)
  stdin.close
  until stdout.eof?
    puts "output from shell: " + stdout.read
  end  # 
  # stdout.close
  # stderr.close
end
# stdout.close

# 
# pid, stdin, stdout, stderr = Open4.popen4("ruby bin/redcar -d --log")
# puts stdin
# stdin.write(text)
# stdin.close
# stderr.close
# # until stdout.eof?
#   puts "output from redcar: " + stdout.read.inspect
# # end
puts "end rbtest"
