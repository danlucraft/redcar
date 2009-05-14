/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcelanguage.c -

  $Author: mutoh $
  $Date: 2005/10/02 18:40:34 $

  Copyright (C) 2004 Ruby-GNOME2 Project Team  
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceLanguage
 * Source language.
 */

#define _SELF(self) (GTK_SOURCE_LANGUAGE(RVAL2GOBJ(self)))

/* Method: id
 * Returns: the id of the language.
 */
static VALUE
sourcelanguage_get_id (self)
	VALUE self;
{
	return CSTR2RVAL (gtk_source_language_get_id (_SELF (self)));
}

/* Method: name
 * Returns: the localized name of the language.
 */
static VALUE
sourcelanguage_get_name (self)
	VALUE self;
{
	return CSTR2RVAL (gtk_source_language_get_name (_SELF (self)));
}

/* Method: section
 * Returns: the localized section of the language, each language belong to a
 * section (ex. HTML belogs to the Markup section).
 */
static VALUE
sourcelanguage_get_section (self)
	VALUE self;
{
	return CSTR2RVAL (gtk_source_language_get_section (_SELF (self)));
}

/*
gboolean            gtk_source_language_get_hidden      (GtkSourceLanguage *language);
*/

/* Method: metadata(name)
 * name: the metadata property name (string)
 * Returns: the localized metadata for the given name.
 */
static VALUE
sourcelanguage_get_metadata (self, name)
	VALUE self, name;
{
	return
		CSTR2RVAL (gtk_source_language_get_metadata
			(_SELF (self), RVAL2CSTR(name)));
}

/* Method: mime_types
 * Returns: a list of mime types for the given language, as an array of strings.
 */
static VALUE
sourcelanguage_get_mime_types (self)
	VALUE self;
{
	VALUE ary;
 	char **types = gtk_source_language_get_mime_types (_SELF (self));
    if (!types)
        return Qnil;
  
    ary = rb_ary_new();
    while (*types){
        rb_ary_push(ary, CSTR2RVAL(*types));
        types++;
    }
    return ary;
}

/* Method: globs
 * Returns: a list of globs for the given language, as an array of strings.
 */
static VALUE
sourcelanguage_get_globs (self)
	VALUE self;
{
	VALUE ary;
 	char **globs = gtk_source_language_get_globs (_SELF (self));
    if (!globs)
        return Qnil;
  
    ary = rb_ary_new();
    while (*globs){
        rb_ary_push(ary, CSTR2RVAL(*globs));
        globs++;
    }
    return ary;
}

/* Method: style_name(style_id)
 * style_id: the style id (string)
 * Returns: the localized style name of the given id.
 */
static VALUE
sourcelanguage_get_style_name (self, style_id)
	VALUE self, style_id;
{
	return
		CSTR2RVAL (gtk_source_language_get_style_name
			(_SELF (self), RVAL2CSTR(style_id)));
}

/* Method: style_id
 * Returns: the styles defined by the language.
 */
static VALUE
sourcelanguage_get_style_ids (self)
	VALUE self;
{
	VALUE ary;
 	gchar **ids = gtk_source_language_get_style_ids (_SELF (self));
    if (!ids)
        return Qnil;
  
    ary = rb_ary_new();
    while (*ids){
        rb_ary_push(ary, CSTR2RVAL(*ids));
        ids++;
    }
    return ary;
}

void
Init_gtk_sourcelanguage ()
{
	VALUE clang =
	    G_DEF_CLASS (GTK_TYPE_SOURCE_LANGUAGE, "SourceLanguage", mGtk);

	rb_define_method (clang, "id", sourcelanguage_get_id, 0);
	rb_define_method (clang, "name", sourcelanguage_get_name, 0);
	rb_define_method (clang, "section", sourcelanguage_get_section, 0);
	rb_define_method (clang, "metadata", sourcelanguage_get_metadata, 1);
	rb_define_method (clang, "mime_types", sourcelanguage_get_mime_types, 0);
	rb_define_method (clang, "globs", sourcelanguage_get_globs, 0);
	rb_define_method (clang, "style_name", sourcelanguage_get_style_name, 1);
	rb_define_method (clang, "style_ids", sourcelanguage_get_style_ids, 0);
	
	G_DEF_SETTERS (clang);
}
