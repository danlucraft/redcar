
#include "ruby.h"
#include <glib.h>

typedef struct Theme_ {
	GSList *settings;
} Theme;

typedef struct ThemeSetting_ {
	char *name;
  char *scope;
	char *foreground;
	char *background;
  char *font_style;
} ThemeSetting;
