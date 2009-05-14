/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcestyleschememanager.c -

  $Author $
  $Date: 2004/08/05 18:13:49 $

  Copyright (C) 2004 Ruby-GNOME2 Project Team
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceStyleSchemeManager
 * A class to manage source style scheme.
 */

#define _SELF(self) (GTK_SOURCE_STYLE_SCHEME_MANAGER(RVAL2GOBJ(self)))

/* Class method: new 
 * Returns: a newly created Gtk::SourceStyleSchemeManager object.
 */
static VALUE
sssm_new (self)
	VALUE self;
{
	G_INITIALIZE (self, gtk_source_style_scheme_manager_new ());
	return Qnil;
}

/* Class method: default
 *
 * Gets the default style scheme manager.
 *
 * Returns: a Gtk::SourceStyleSchemeManager
 */
static VALUE
sssm_get_default(self)
    VALUE self;
{
    GtkSourceStyleSchemeManager* sssm = gtk_source_style_scheme_manager_get_default();
    GType gtype = G_TYPE_FROM_INSTANCE(sssm);

    gchar *gtypename = (gchar *) g_type_name (gtype);
    if (strncmp (gtypename, "Gtk", 3) == 0)
        gtypename += 3;
    if (!rb_const_defined_at (mGtk, rb_intern (gtypename)))
        G_DEF_CLASS (gtype, gtypename, mGtk);

    return GOBJ2RVAL(sssm);
}

/* Method: set_search_path(dirs)
 * dirs: style scheme file directory path
 *
 * Sets the style scheme files directories for the given style scheme manager.
 *
 * Returns: self.
 */
static VALUE
sssm_set_search_path (self, dirs)
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
	
	gtk_source_style_scheme_manager_set_search_path (_SELF (self), gdirs);
	return self;
}

/* Method: append_search_path(path)
 * path: additional style scheme file directory path (string)
 *
 * Appends the style scheme files directory for the given style scheme manager.
 *
 * Returns: self.
 */
static VALUE
sssm_append_search_path (self, path)
	VALUE self, path;
{
	gtk_source_style_scheme_manager_append_search_path (_SELF (self), RVAL2CSTR(path));
	return self;
}

/* Method: prepend_search_path(path)
 * path: additional style scheme file directory path (string)
 *
 * Prepend the style scheme files directory for the given style scheme manager.
 *
 * Returns: self.
 */
static VALUE
sssm_prepend_search_path (self, path)
	VALUE self, path;
{
	gtk_source_style_scheme_manager_prepend_search_path (_SELF (self), RVAL2CSTR(path));
	return self;
}

/* Method: get_search_path
 * Returns: a list of style scheme files directories (strings) for the given
 * style scheme manager.
 */
static VALUE
sssm_get_search_path (self)
	VALUE self;
{
	VALUE ary;
 	const gchar * const * dirs =
            gtk_source_style_scheme_manager_get_search_path (_SELF (self));
    if (!dirs)
        return Qnil;
  
    ary = rb_ary_new();
    while (*dirs){
        rb_ary_push(ary, CSTR2RVAL(*dirs));
        dirs++;
    }
    return ary;
}

/* Method: scheme_ids 
 * Returns: a list of style scheme ids for the given style scheme manager
 */
static VALUE
sssm_get_scheme_ids (self)
	VALUE self;
{
	VALUE ary;
 	const gchar * const * ids =
            gtk_source_style_scheme_manager_get_scheme_ids (_SELF (self));
    if (!ids)
        return Qnil;
  
    ary = rb_ary_new();
    while (*ids){
        rb_ary_push(ary, CSTR2RVAL(*ids));
        ids++;
    }
    return ary;
}

/*
 * Method: scheme(scheme_id)
 * scheme_id: a style scheme id (as a string).
 *
 * Gets the Gtk::SourceStyleScheme which is associated with the given id
 * in the style scheme manager.
 *
 * Returns: a Gtk::SourceStyleScheme, or nil if there is no style scheme 
 * associated with the given id.
 */
static VALUE
sssm_get_scheme (self, scheme_id)
	VALUE self, scheme_id;
{
	return
	    GOBJ2RVAL (gtk_source_style_scheme_manager_get_scheme
		       (_SELF (self), RVAL2CSTR (scheme_id)));
}

/*
 * Method: force_rescan
 *
 * Forces all style schemes to be reloaded the next time the
 * Gtk::SourceStyleSchemeManager is accessed.
 *
 * Returns: self.
 */
static VALUE
sssm_force_rescan (self)
	VALUE self;
{
	gtk_source_style_scheme_manager_force_rescan(_SELF (self));
	return self;
}

void
Init_gtk_sourcestyleschememanager ()
{
	VALUE csssm =
	    G_DEF_CLASS (GTK_TYPE_SOURCE_STYLE_SCHEME_MANAGER,
			 "SourceStyleSchemeManager", mGtk);

	rb_define_method (csssm, "initialize", sssm_new, 0);
	rb_define_method (csssm, "set_search_path", sssm_set_search_path, 1);
	rb_define_method (csssm, "append_search_path", sssm_append_search_path, 1);
	rb_define_method (csssm, "prepend_search_path", sssm_prepend_search_path, 1);
	rb_define_method (csssm, "get_search_path", sssm_get_search_path, 0);
	rb_define_method (csssm, "scheme_ids", sssm_get_scheme_ids, 0);
	rb_define_method (csssm, "scheme", sssm_get_scheme, 1);
	rb_define_method (csssm, "force_rescan", sssm_force_rescan, 0);
	rb_define_singleton_method(csssm, "default", sssm_get_default, 0);
	G_DEF_SETTERS (csssm);
}
