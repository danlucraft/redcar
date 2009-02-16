#!/usr/bin/env ruby

text = <<TXT
Foo
Barand
BazBazBaz
Quxand
TXT

require 'rubygems'
require 'open4'

pid, stdin, stdout, stderr = Open4.popen4("python pytest.py")
stdin.write(text)
stdin.close
until stdout.eof?
  puts stdout.read
end
stdout.close
