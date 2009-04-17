Frequently Asked Questions
==========================

**When I try to start Redcar I see a "get_node" error**.

  Are you on Jaunty? There seems to be a bug in the ruby-dbus package
  for Jaunty, or a bug in how Redcar uses it. A workaround for now is
  to start Redcar with the flag *--multiple-instances*.

**Super+R (or some other key) doesn't seem to work**

  Do you use Compiz? Many Compiz keybindings conflict with Redcar
  keybindings. Super+R is the default for "Enhanced Zoom Desktop" for
  instance. You can modify Compiz keybindings in the Compiz Settings 
  Manager. You can modify Redcar keybindings by looking in the source :)

**When I try to build Redcar, I get "error: rbgtkconversions.h: No such file or directory"**

  Are you running on Debian Squeeze? The Ruby-GNOME2 package
  seems to be missing some header files. You can download them 
  `here <http://redcareditor.com/stuff/missing_x64_headers>`_ and you should put them
  in the same place as the rbgtk.h header. Which may be */usr/lib/ruby/1.8/x86_64-linux/*
