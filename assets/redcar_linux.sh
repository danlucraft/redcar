#!/bin/sh
if [ -h "$0" ]
then
  BASEDIR=`dirname $(readlink $0)`
else
  BASEDIR=`dirname $0`
fi
  
exec java -Dfile.encoding=UTF8 -d32 -classpath $BASEDIR/../lib/redcar/vendor/jruby-complete.jar:$BASEDIR org.jruby.Main $BASEDIR/../lib/redcar/bin/redcar --no-sub-jruby "$@"
