
#include "ruby.h"
#include <glib.h>
#include <string.h>

typedef struct SinglePattern_ {
  char* name;
} SinglePattern;

typedef struct DoublePattern_ {
  char* name;
} DoublePattern;

static VALUE cEditView, cPattern;
void Init_pattern() {
  cEditView = rb_eval_string("Redcar::EditView");
  cPattern = rb_define_class_under(cEditView, "Pattern", rb_cObject);
}
