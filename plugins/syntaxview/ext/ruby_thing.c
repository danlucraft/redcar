
#include "ruby.h"

#include <gtk/gtk.h>

typedef struct {
    VALUE self;
    GObject* gobj;
    void* cinfo;
    gboolean destroyed;
} gobj_holder;

static VALUE thing_get_gobj(VALUE self, void *rbgobj) {
  gobj_holder *gh;
  Data_Get_Struct(rbgobj, gobj_holder, gh);
  GtkWidget *window = (GtkWidget *) gh->gobj;
  gtk_window_set_title(GTK_WINDOW(window), "Hello from C");
  return self;
}

/* The C Object */

typedef struct Thing_ {
  int a;
  int b;
} Thing;

void thing_init(Thing *thing) {
  thing->a = 0;
  thing->b = 0;
}

void thing_destroy(Thing *thing) {
  free(thing);
}

void thing_print(Thing *thing) {
  printf("a: %d, b: %d\n", thing->a, thing->b);
}

/* The Ruby Interface */

static VALUE cThing;

static void thing_free(void *thing) {
  thing_destroy(thing);
}

static VALUE thing_alloc(VALUE klass) {
  Thing *thing = malloc(sizeof(Thing));
  VALUE obj;

  thing_init(thing);
  obj = Data_Wrap_Struct(klass, 0, thing_free, thing);
  return obj;
}

static VALUE thing_initialize(VALUE self) {
  return self;
}

static VALUE thing_display(VALUE self) {
  Thing *t;
  Data_Get_Struct(self, Thing, t);
  thing_print(t);
  return Qnil;
}

void Init_ruby_thing() {
  cThing = rb_define_class("Thing", rb_cObject);
  rb_define_alloc_func(cThing, thing_alloc);
  rb_define_method(cThing, "initialize", thing_initialize, 0);
  rb_define_method(cThing, "display", thing_display, 0);
  rb_define_method(cThing, "get_gobj", thing_get_gobj, 1);
}
