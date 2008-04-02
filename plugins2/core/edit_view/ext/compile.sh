make clean
gcc -I. -I/usr/local/lib/ruby/1.8/i686-linux -I/usr/local/lib/ruby/1.8/i686-linux -I.  -fPIC -g -O2  -c syntax_ext.c `pkg-config --cflags gtk+-2.0` `pkg-config --libs gtk+-2.0`
gcc -shared -rdynamic -Wl,-export-dynamic   -L'/usr/local/lib' -Wl,-R'/usr/local/lib' -o syntax_ext.so syntax_ext.o -lonig -ldl -lcrypt -lm   -lc
