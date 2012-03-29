#!/bin/sh
BASEDIR=`dirname $0`
exec java -XstartOnFirstThread -Dfile.encoding=UTF8 -d32 -classpath $BASEDIR/vendor/jruby-complete.jar:$BASEDIR org.jruby.Main $BASEDIR/bin/redcar --no-sub-jruby --show-log --log-level=debug
