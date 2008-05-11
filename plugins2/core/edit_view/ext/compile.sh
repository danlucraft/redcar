make clean

gcc -I. -I/usr/local/lib/ruby/1.8/i686-linux -I/usr/local/lib/ruby/1.8/i686-linux -I.  -fPIC -g -O2  -c textloc.c `pkg-config --cflags gtk+-2.0 gtksourceview-1.0` `pkg-config --libs gtk+-2.0 gtksourceview-1.0`
gcc -shared -rdynamic -Wl,-export-dynamic   -L'/usr/local/lib' -Wl,-R'/usr/local/lib' -o textloc.so textloc.o -ldl -lcrypt -lm   -lc

gcc -I. -I/usr/local/lib/ruby/1.8/i686-linux -I/usr/local/lib/ruby/1.8/i686-linux -I.  -fPIC -g -O2  -c scope.c `pkg-config --cflags gtk+-2.0 gtksourceview-1.0` `pkg-config --libs gtk+-2.0 gtksourceview-1.0`
gcc -shared -rdynamic -Wl,-export-dynamic   -L'/usr/local/lib' -Wl,-R'/usr/local/lib' -o scope.so scope.o -ldl -lcrypt -lm   -lc

gcc -I. -I/usr/local/lib/ruby/1.8/i686-linux -I/usr/local/lib/ruby/1.8/i686-linux -I.  -fPIC -g -O2  -c pattern.c `pkg-config --cflags gtk+-2.0 gtksourceview-1.0` `pkg-config --libs gtk+-2.0 gtksourceview-1.0`
gcc -shared -rdynamic -Wl,-export-dynamic   -L'/usr/local/lib' -Wl,-R'/usr/local/lib' -o pattern.so pattern.o -lonig -ldl -lcrypt -lm   -lc

gcc -I. -I/usr/local/lib/ruby/1.8/i686-linux -I/usr/local/lib/ruby/1.8/i686-linux -I.  -fPIC -g -O2  -c line_parser.c `pkg-config --cflags gtk+-2.0 gtksourceview-1.0` `pkg-config --libs gtk+-2.0 gtksourceview-1.0`
gcc -shared -rdynamic -Wl,-export-dynamic   -L'/usr/local/lib' -Wl,-R'/usr/local/lib' -o line_parser.so line_parser.o -lonig -ldl -lcrypt -lm   -lc