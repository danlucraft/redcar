
#include "ruby.h"
#include "theme.h"
#include <glib.h>

#define RSTRING_PTR_OR_NULL(s) (s == Qnil ? NULL : RSTRING_PTR(s))
 
static void rb_theme_destroy(void* theme) {
  free(theme);
}

static VALUE rb_theme_alloc(VALUE klass) {
  Theme *theme = malloc(sizeof(Theme));
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_theme_destroy, theme);
	theme->settings = NULL;
  return obj;
}

static VALUE rb_theme_create_setting(VALUE self, VALUE rb_name, VALUE rb_scope, 
																		 VALUE rb_foreground, VALUE rb_background, 
																		 VALUE rb_font_style) {
  Theme *theme;
  Data_Get_Struct(self, Theme, theme);
	ThemeSetting *setting = malloc(sizeof(ThemeSetting));
	// FIXME check return value
	setting->name       = RSTRING_PTR_OR_NULL(rb_name);
	setting->scope      = RSTRING_PTR_OR_NULL(rb_scope);
	setting->foreground = RSTRING_PTR_OR_NULL(rb_foreground);
	setting->background = RSTRING_PTR_OR_NULL(rb_background);
	setting->font_style = RSTRING_PTR_OR_NULL(rb_font_style);
	theme->settings = g_slist_append(theme->settings, setting);
	return Qnil;
}

static VALUE cTheme, rb_cEditView;

void Init_theme() {
  rb_cEditView = rb_eval_string("Redcar::EditView");

  cTheme = rb_define_class_under(rb_cEditView, "Theme", rb_cObject);
  rb_define_alloc_func(cTheme, rb_theme_alloc);
	rb_define_method(cTheme, "create_setting", rb_theme_create_setting, 5);
}
