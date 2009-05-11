/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcestylescheme.c -

  $Author: mutoh $
  $Date: 2005/10/02 18:40:34 $

  Copyright (C) 2005  Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Module: Gtk::SourceStyleScheme
 */

#define _SELF(self) (GTK_SOURCE_STYLE_SCHEME(RVAL2GOBJ(self)))

/* Method: id
 *
 * Gets the id of the given style scheme.
 *
 * Returns: the id of the style scheme.
 */
static VALUE
scheme_get_id(self)
    VALUE self;
{
    return CSTR2RVAL((gchar*)gtk_source_style_scheme_get_id(_SELF(self)));
}

/* Method: name
 *
 * Gets the name of the given style scheme.
 *
 * Returns: the name of the style scheme.
 */
static VALUE
scheme_get_name(self)
    VALUE self;
{
    return CSTR2RVAL((gchar*)gtk_source_style_scheme_get_name(_SELF(self)));
}

/* Method: description
 *
 * Gets the description of the given style scheme.
 *
 * Returns: the description of the style scheme.
 */
static VALUE
scheme_get_description(self)
    VALUE self;
{
    return CSTR2RVAL((gchar*)gtk_source_style_scheme_get_description(_SELF(self)));
}

/* Method: authors
 *
 * Returns: a list of authors for the given style scheme.
 */
static VALUE
scheme_get_authors (self)
	VALUE self;
{
	VALUE ary;
 	const gchar * const * authors =
            gtk_source_style_scheme_get_authors (_SELF (self));
    if (!authors)
        return Qnil;
  
    ary = rb_ary_new();
    while (*authors){
        rb_ary_push(ary, CSTR2RVAL(*authors));
        authors++;
    }
    return ary;
}

/* Method: filename
 *
 * Gets the filename of the given style scheme.
 *
 * Returns: the filename of the style scheme.
 */
static VALUE
scheme_get_filename(self)
    VALUE self;
{
    return CSTR2RVAL((gchar*)gtk_source_style_scheme_get_filename(_SELF(self)));
}

/* Method: get_style(style_id)
 * style_name: the name of a style.
 *
 * Gets the tag associated with the given style_name in the style scheme.
 *
 * Returns: Gtk::SourceStyle
 */
static VALUE
scheme_get_style(self, style_name)
    VALUE self, style_name;
{
    return GOBJ2RVAL(gtk_source_style_scheme_get_style(_SELF(self), 
                                                       RVAL2CSTR(style_name)));
}

void
Init_gtk_sourcestylescheme ()
{
    VALUE scheme = G_DEF_CLASS (GTK_TYPE_SOURCE_STYLE_SCHEME, "SourceStyleScheme", mGtk);
    
    rb_define_method(scheme, "id", scheme_get_id, 0);
    rb_define_method(scheme, "name", scheme_get_name, 0);
    rb_define_method(scheme, "description", scheme_get_description, 0);
    rb_define_method(scheme, "authors", scheme_get_authors, 0);
    rb_define_method(scheme, "filename", scheme_get_filename, 0);
    rb_define_method(scheme, "get_style", scheme_get_style, 1);
}
