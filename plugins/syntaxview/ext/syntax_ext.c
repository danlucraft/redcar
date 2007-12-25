
#include "ruby.h"
#include <gtk/gtk.h>
#include "textloc.h"
#include <glib.h>

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

typedef struct ScopeData_ {
  int a;
} ScopeData;

typedef GNode Scope;

static VALUE scope_init(VALUE self) {
  return self;
}

void scope_destroy(Scope* scope) {
  g_node_destroy((gpointer) scope);
  return;
}

static VALUE scope_alloc(VALUE klass) {
  Scope *scope;
  VALUE obj;

  scope = g_node_new(NULL);
  obj = Data_Wrap_Struct(klass, 0, scope_destroy, scope);
  return obj;
}

static VALUE scope_print(VALUE rb_scope) {
  printf("scope\n");
  return Qnil;
}

static VALUE mSyntaxExt;
static VALUE cScope;

void Init_syntax_ext() {
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "set_window_title", set_window_title, 2);
  cScope = rb_define_class("CScope", rb_cObject);
  rb_define_alloc_func(cScope, scope_alloc);
  rb_define_method(cScope, "initialize", scope_init, 0);
  rb_define_method(cScope, "display", scope_print, 0);
}
