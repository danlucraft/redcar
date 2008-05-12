
#include "ruby.h"
#include "theme.h"

static void rb_theme_destroy(void* theme) {
  free(theme);
}

static VALUE rb_theme_alloc(VALUE klass) {
  Theme *theme = malloc(sizeof(Theme));
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_theme_destroy, theme);
  return obj;
}

static VALUE cTheme, rb_cEditView;

void Init_theme() {
  rb_cEditView = rb_eval_string("Redcar::EditView");

  cTheme = rb_define_class_under(rb_cEditView, "Theme", rb_cObject);
  rb_define_alloc_func(cTheme, rb_theme_alloc);
}
