/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcelanguagemanager.c -

  $Author $
  $Date: 2004/08/05 18:13:49 $

  Copyright (C) 2004 Ruby-GNOME2 Project Team
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceLanguageManager
 * A class to manage source language.
 */

#define _SELF(self) (GTK_SOURCE_LANGUAGE_MANAGER(RVAL2GOBJ(self)))

/* Class method: new 
 * Returns: a newly created Gtk::SourceLanguageManager object.
 */
static VALUE
slm_new (self)
	VALUE self;
{
	G_INITIALIZE (self, gtk_source_language_manager_new ());
	return Qnil;
}

/* Class method: default
 *
 * Gets the default language manager.
 *
 * Returns: a Gtk::SourceLanguageManager
 */
static VALUE
slm_get_default(self)
    VALUE self;
{
    GtkSourceLanguageManager* slm = gtk_source_language_manager_get_default();
    GType gtype = G_TYPE_FROM_INSTANCE(slm);

    gchar *gtypename = (gchar *) g_type_name (gtype);
    if (strncmp (gtypename, "Gtk", 3) == 0)
        gtypename += 3;
    if (!rb_const_defined_at (mGtk, rb_intern (gtypename)))
        G_DEF_CLASS (gtype, gtypename, mGtk);

    return GOBJ2RVAL(slm);
}

/*
 * Method: get_language(id)
 * id: a language id (as a string).
 *
 * Gets the Gtk::SourceLanguage which is associated with the given id
 * in the language manager.
 *
 * Returns: a Gtk::SourceLanguage, or nil if there is no language associated
 * with the given id.
 */
static VALUE
slm_get_language (self, id)
	VALUE self, id;
{
	return
	    GOBJ2RVAL (gtk_source_language_manager_get_language
		       (_SELF (self), RVAL2CSTR (id)));
}

/* Method: get_search_path
 * Returns: a list of language files directories (strings) for the given
 * language manager.
 */
static VALUE
slm_get_search_path (self)
	VALUE self;
{
	VALUE ary;
 	const gchar * const * dirs =
            gtk_source_language_manager_get_search_path (_SELF (self));
    if (!dirs)
        return Qnil;
  
    ary = rb_ary_new();
    while (*dirs){
        rb_ary_push(ary, CSTR2RVAL(*dirs));
        dirs++;
    }
    return ary;
}

/* Method: set_search_path(dirs)
 * dirs: language file directory path
 *
 * Sets the language files directories for the given language manager.
 *
 * Returns: self.
 */
static VALUE
slm_set_search_path (self, dirs)
	VALUE self, dirs;
{
    gchar** gdirs = (gchar**)NULL;
	gint i;

    if (! NIL_P(dirs)){
        Check_Type(dirs, T_ARRAY);
        i = RARRAY(dirs)->len;
        gdirs = ALLOCA_N(gchar*, i + 1);
        for (i = 0; i < i; i++) {
            if (TYPE(RARRAY(dirs)->ptr[i]) == T_STRING) {
                gdirs[i] = RVAL2CSTR(RARRAY(dirs)->ptr[i]);
            }
            else {
                gdirs[i] = "";
            }
        }
        gdirs[i] = (gchar*)NULL;
    }
	
	gtk_source_language_manager_set_search_path (_SELF (self), gdirs);

	return self;
}

/* Method: language_ids 
 * Returns: a list of languages ids for the given language manager
 */
static VALUE
slm_get_language_ids (self)
	VALUE self;
{
	VALUE ary;
 	const gchar * const * ids =
            gtk_source_language_manager_get_language_ids (_SELF (self));
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
Init_gtk_sourcelanguagemanager ()
{
	VALUE cslm =
	    G_DEF_CLASS (GTK_TYPE_SOURCE_LANGUAGE_MANAGER,
			 "SourceLanguageManager", mGtk);

	rb_define_method (cslm, "initialize", slm_new, 0);
	rb_define_method (cslm, "get_language", slm_get_language, 1);
	rb_define_method (cslm, "get_search_path", slm_get_search_path, 0);
	rb_define_method (cslm, "set_search_path", slm_set_search_path, 1);
	rb_define_method (cslm, "language_ids", slm_get_language_ids, 0);
	rb_define_singleton_method(cslm, "default", slm_get_default, 0);
	G_DEF_SETTERS (cslm);
}
