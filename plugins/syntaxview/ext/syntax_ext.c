
#include "ruby.h"
#include <gtk/gtk.h>

typedef struct {
    VALUE self;
    GObject* gobj;
    void* cinfo;
    gboolean destroyed;
} gobj_holder;

GObject* get_gobject(VALUE rbgobj) {
  gobj_holder *gh;
  Data_Get_Struct(rbgobj, gobj_holder, gh);
  return gh->gobj;
}

static VALUE set_window_title(VALUE self, VALUE rbgobj, VALUE title) {
  GtkWidget *window = (GtkWidget *) get_gobject(rbgobj);
  gtk_window_set_title(GTK_WINDOW(window), RSTRING_PTR(title));
  return self;
}

static VALUE make_red(VALUE self, VALUE rg_buffer) {
  GtkTextIter start, end;
  GtkTextBuffer *buf = (GtkTextBuffer *) get_gobject(rg_buffer);
  GtkTextTag *tag;

  tag = gtk_text_buffer_create_tag (buf, "colors", "foreground", "#FF0000", NULL);
  gtk_text_buffer_get_selection_bounds (buf, &start, &end);
  gtk_text_buffer_apply_tag_by_name (buf, "colors", &start, &end);
}

typedef struct TextLoc_ {
  int line;
  int offset;
} TextLoc;

int textloc_equal(TextLoc t1, TextLoc t2) {
  return t1.line == t2.line && t1.offset == t2.offset;
}

TextLoc scope_get_start(VALUE scope) {
  VALUE start = rb_iv_get(scope, "@start");
  TextLoc tl;
  tl.line   = FIX2INT(rb_iv_get(start, "@line"));
  tl.offset = FIX2INT(rb_iv_get(start, "@offset"));
  return tl;
}

TextLoc scope_get_end(VALUE scope) {
  VALUE start = rb_iv_get(scope, "@end");
  TextLoc tl;
  tl.line   = FIX2INT(rb_iv_get(start, "@line"));
  tl.offset = FIX2INT(rb_iv_get(start, "@offset"));
  return tl;
}

static VALUE colour_line_with_scopes(VALUE self, VALUE colourer, 
				     VALUE line_num, VALUE scopes) {
  printf("colouring line\n");
  VALUE rg_buffer = rb_iv_get(colourer, "@buffer");
  GtkTextBuffer *buffer = (GtkTextBuffer *) get_gobject(rg_buffer);
  GtkTextIter start_iter, end_iter;
  gtk_text_buffer_get_iter_at_line_offset(buffer, &start_iter, FIX2INT(line_num), 0);
  gtk_text_buffer_get_iter_at_line_offset(buffer, &end_iter, FIX2INT(line_num)+1, 0);
  gtk_text_buffer_remove_all_tags(buffer, &start_iter, &end_iter);
  
  int length = RARRAY(scopes)->len;
  int i;
  TextLoc locs, loce;
  for (i = 0; i < length; i++) {
    locs = scope_get_start(rb_ary_entry(scopes, (long) i));
    loce = scope_get_end(rb_ary_entry(scopes, (long) i));
    if (!textloc_equal(locs, loce))
      printf("start: (%d,%d)  end: (%d, %d)\n", locs.line, locs.offset, loce.line, loce.offset);
  }
  return self;
}

static VALUE mSyntaxExt;

void Init_syntax_ext() {
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "set_window_title", set_window_title, 2);
  rb_define_module_function(mSyntaxExt, "make_red", make_red, 1);
  rb_define_module_function(mSyntaxExt, "colour_line_with_scopes", colour_line_with_scopes, 3);
}
