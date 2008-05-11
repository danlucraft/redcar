
#include "ruby.h"
#include "textloc.h"
#include <gtk/gtk.h>

int textloc_init(TextLoc* t) {
  t->line = -1;
  t->offset = -1;
}

int textloc_equal(TextLoc* t1, TextLoc* t2) {
  return (t1->line == t2->line && t1->offset == t2->offset);
}

int textloc_gt(TextLoc* t1, TextLoc* t2) {
  return ((t1->line > t2->line) || (t1->line >= t2->line && t1->offset > t2->offset));
}

int textloc_lt(TextLoc* t1, TextLoc* t2) {
  return (!textloc_equal(t1, t2) && !textloc_gt(t1, t2));
}

int textloc_gte(TextLoc* t1, TextLoc* t2) {
  return (!textloc_lt(t1, t2));
}

int textloc_lte(TextLoc* t1, TextLoc* t2) {
  return (!textloc_gt(t1, t2));
}

int textloc_valid(TextLoc* t) {
  return (t->line != -1 && t->offset != -1);
}

void mark_to_textloc(GtkTextMark* mark, TextLoc* textloc) {
  GtkTextBuffer* buffer;
  GtkTextIter iter;
  buffer = gtk_text_mark_get_buffer(mark);
  gtk_text_buffer_get_iter_at_mark(buffer, &iter, mark);
  textloc->line   = (int) gtk_text_iter_get_line(&iter);
  textloc->offset = (int) gtk_text_iter_get_line_offset(&iter);
  return;
}

static void rb_textloc_destroy(void* tl) {
  free(tl);
}

static VALUE rb_textloc_alloc(VALUE klass) {
  TextLoc *textloc = malloc(sizeof(TextLoc));
  textloc_init(textloc);
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_textloc_destroy, textloc);
  return obj;
}

static VALUE rb_textloc_init(VALUE self, VALUE line, VALUE offset) {
  TextLoc *textloc;
  Data_Get_Struct(self, TextLoc, textloc);
  textloc->line = FIX2INT(line);
  textloc->offset = FIX2INT(offset);
  return self;
}

static VALUE rb_textloc_line(VALUE self, VALUE rbt) {
  TextLoc *t;
  Data_Get_Struct(self, TextLoc, t);
  return INT2FIX(t->line);
}

static VALUE rb_textloc_offset(VALUE self, VALUE rbt) {
  TextLoc *t;
  Data_Get_Struct(self, TextLoc, t);
  return INT2FIX(t->offset);
}

static VALUE rb_textloc_equal(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  if (rbt == Qnil) {
    if (!textloc_valid(t1))
      return Qtrue;
    else
      return Qfalse;
  }
	
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_equal(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_lt(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_lt(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_gt(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_gt(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_gte(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_gte(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_lte(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_lte(t1, t2))
    return Qtrue;
  return Qfalse;
}


static VALUE cTextLoc, rb_cEditView;

void Init_textloc() {
  rb_cEditView = rb_eval_string("Redcar::EditView");

  cTextLoc = rb_define_class_under(rb_cEditView, "TextLoc", rb_cObject);
  rb_define_alloc_func(cTextLoc, rb_textloc_alloc);
  rb_define_method(cTextLoc, "initialize", rb_textloc_init, 2);
  rb_define_method(cTextLoc, "line", rb_textloc_line, 0);
  rb_define_method(cTextLoc, "offset", rb_textloc_offset, 0);
  rb_define_method(cTextLoc, "==", rb_textloc_equal, 1);
  rb_define_method(cTextLoc, "<", rb_textloc_lt, 1);
  rb_define_method(cTextLoc, ">", rb_textloc_gt, 1);
  rb_define_method(cTextLoc, "<=", rb_textloc_lte, 1);
  rb_define_method(cTextLoc, ">=", rb_textloc_gte, 1);
}
