/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourceprintcompositor.c -

  $Author: ggc $
  $Date: 2007/07/13 16:07:33 $

  Copyright (C) 2005  Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Module: Gtk::SourcePrintCompositor
 */
#define _SELF(self) (GTK_SOURCE_PRINT_COMPOSITOR(RVAL2GOBJ(self)))
#define DBL2NUM(v)  rb_float_new(v)

/*
 * Class method: new(buffer)
 * buffer: a Gtk::SourceBuffer object.
 *
 * Creates a new print compositor to print buffer.
 * 
 * Returns: the new print compositor object.
 */
static VALUE
sprintcompositor_initialize (self, buffer)
    VALUE self, buffer;
{
    G_INITIALIZE(self,
        gtk_source_print_compositor_new(GTK_SOURCE_BUFFER(RVAL2GOBJ(buffer))));
    return self;
}

static VALUE
sprintcompositor_setup(self, view)
    VALUE self, view;
{
    G_INITIALIZE(self,
        gtk_source_print_compositor_new_from_view(GTK_SOURCE_VIEW(RVAL2GOBJ(view))));
    return self;
}

static VALUE
sprintcompositor_get_top_margin(self, unit)
    VALUE self, unit;
{
    return DBL2NUM(gtk_source_print_compositor_get_top_margin(_SELF(self), unit));
}

static VALUE
sprintcompositor_set_top_margin(self, top, unit)
    VALUE self, top, unit;
{
    gtk_source_print_compositor_set_top_margin(_SELF(self), NUM2DBL(top), unit);
    return self;
}

static VALUE
sprintcompositor_get_bottom_margin(self, unit)
    VALUE self, unit;
{
    return DBL2NUM(gtk_source_print_compositor_get_bottom_margin(_SELF(self), unit));
}

static VALUE
sprintcompositor_set_bottom_margin(self, bottom, unit)
    VALUE self, bottom, unit;
{
    gtk_source_print_compositor_set_bottom_margin(_SELF(self), NUM2DBL(bottom), unit);
    return self;
}

static VALUE
sprintcompositor_get_left_margin(self, unit)
    VALUE self, unit;
{
    return DBL2NUM(gtk_source_print_compositor_get_left_margin(_SELF(self), unit));
}

static VALUE
sprintcompositor_set_left_margin(self, left, unit)
    VALUE self, left, unit;
{
    gtk_source_print_compositor_set_left_margin(_SELF(self), NUM2DBL(left), unit);
    return self;
}

static VALUE
sprintcompositor_get_right_margin(self, unit)
    VALUE self, unit;
{
    return DBL2NUM(gtk_source_print_compositor_get_right_margin(_SELF(self), unit));
}

static VALUE
sprintcompositor_set_right_margin(self, right, unit)
    VALUE self, right, unit;
{
    gtk_source_print_compositor_set_right_margin(_SELF(self), NUM2DBL(right), unit);
    return self;
}

static VALUE
sprintcompositor_get_n_pages(self)
    VALUE self;
{
    return UINT2NUM(gtk_source_print_compositor_get_n_pages(_SELF(self)));
}

/* Defined as properties
void        gtk_source_print_compositor_set_print_header
                                            (GtkSourcePrintCompositor *compositor,
                                             gboolean setting);
gboolean    gtk_source_print_compositor_get_print_header
                                            (GtkSourcePrintCompositor *compositor);
void        gtk_source_print_compositor_set_print_footer
                                            (GtkSourcePrintCompositor *compositor,
                                             gboolean setting);
gboolean    gtk_source_print_compositor_get_print_footer
                                            (GtkSourcePrintCompositor *compositor);
*/

static VALUE
sprintcompositor_set_header_format(self, left, center, right, separator)
    VALUE self, left, center, right, separator;
{
    gtk_source_print_compositor_set_header_format(_SELF(self),
                                           RVAL2CBOOL(separator),
                                           (const gchar*)RVAL2CSTR(left),
                                           (const gchar*)RVAL2CSTR(center),
                                           (const gchar*)RVAL2CSTR(right));
    return self;
}

static VALUE
sprintcompositor_set_footer_format(self, left, center, right, separator)
    VALUE self, left, center, right, separator;
{
    gtk_source_print_compositor_set_footer_format(_SELF(self),
                                            RVAL2CBOOL(separator),
                                           (const gchar*)RVAL2CSTR(left),
                                           (const gchar*)RVAL2CSTR(center),
                                           (const gchar*)RVAL2CSTR(right));
    return self;
}

void
Init_gtk_sourceprintcompositor()
{
    VALUE pj = G_DEF_CLASS(GTK_TYPE_SOURCE_PRINT_COMPOSITOR, "SourcePrintCompositor", mGtk);
    
    rb_define_method(pj, "initialize", sprintcompositor_initialize, 1);
    rb_define_method(pj, "setup", sprintcompositor_setup, 1);
    rb_define_method(pj, "top_margin", sprintcompositor_get_top_margin, 1);
    rb_define_method(pj, "set_top_margin", sprintcompositor_set_top_margin, 2);
    rb_define_method(pj, "bottom_margin", sprintcompositor_get_bottom_margin, 1);
    rb_define_method(pj, "set_bottom_margin", sprintcompositor_set_bottom_margin, 2);
    rb_define_method(pj, "left_margin", sprintcompositor_get_left_margin, 1);
    rb_define_method(pj, "set_left_margin", sprintcompositor_set_left_margin, 2);
    rb_define_method(pj, "right_margin", sprintcompositor_get_right_margin, 1);
    rb_define_method(pj, "set_right_margin", sprintcompositor_set_right_margin, 2);
    rb_define_method(pj, "n_pages", sprintcompositor_get_n_pages, 0);
    rb_define_method(pj, "set_header_format", sprintcompositor_set_header_format, 4);
    rb_define_method(pj, "set_footer_format", sprintcompositor_set_footer_format, 4);

    G_DEF_SETTERS(pj);
}
