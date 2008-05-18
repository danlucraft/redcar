
#include "ruby.h"
#include "pattern.h"
#include <glib.h>
#include <string.h>

static void rb_single_pattern_destroy(void* tl) {
  free(tl);
}

void single_pattern_init(SinglePattern* single_pattern) {
	single_pattern->name = NULL;
	single_pattern->match = NULL;
}

static VALUE rb_single_pattern_alloc(VALUE klass) {
  SinglePattern *single_pattern = malloc(sizeof(SinglePattern));
  single_pattern_init(single_pattern);
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_single_pattern_destroy, single_pattern);
  return obj;
}

static void rb_double_pattern_destroy(void* tl) {
  free(tl);
}

void double_pattern_init(DoublePattern* double_pattern) {
	double_pattern->name = NULL;
	double_pattern->match = NULL;
}

static VALUE rb_double_pattern_alloc(VALUE klass) {
  DoublePattern *double_pattern = malloc(sizeof(DoublePattern));
  double_pattern_init(double_pattern);
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_double_pattern_destroy, double_pattern);
  return obj;
}

static VALUE cEditView, cPattern, cSinglePattern, cDoublePattern;
void Init_pattern() {
  cEditView = rb_eval_string("Redcar::EditView");
  cPattern = rb_define_class_under(cEditView, "CPattern", rb_cObject);
  cSinglePattern = rb_define_class_under(cEditView, "CSinglePattern", cPattern);
	cDoublePattern = rb_define_class_under(cEditView, "CDoublePattern", cPattern);
  rb_define_alloc_func(cSinglePattern, rb_single_pattern_alloc);
  rb_define_alloc_func(cDoublePattern, rb_double_pattern_alloc);
}
