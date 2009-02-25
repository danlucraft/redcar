
require 'rubygems'
require 'oniguruma'

reg = Oniguruma::ORegex.new( '(?<before>.*)(a)(?<after>.*)' )
 match = reg.match( 'terraforming' )
 puts match[0]         <= 'terraforming'
 puts match[:before]   <= 'terr'
 puts match[:after]    <= 'forming'
