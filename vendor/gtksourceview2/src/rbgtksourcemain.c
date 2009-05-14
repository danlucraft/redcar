/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcemain.c -

  $Author $
  $Date: 2005/10/07 19:26:15 $

  Copyright (C) 2004,2005 Ruby-GNOME2 Project Team
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

extern void Init_gtk_sourceview (void);
extern void Init_gtk_sourcebuffer (void);
extern void Init_gtk_sourceiter (void);
extern void Init_gtk_sourcelanguage (void);
extern void Init_gtk_sourcelanguagemanager (void);
extern void Init_gtk_sourcemark (void);
extern void Init_gtk_sourceprintcompositor (void);
extern void Init_gtk_sourcestylescheme (void);
extern void Init_gtk_sourcestyleschememanager (void);

void
Init_gtksourceview2 (void)
{
    Init_gtk_sourceview ();
    Init_gtk_sourcebuffer ();
    Init_gtk_sourceiter ();
    Init_gtk_sourcelanguage ();
    Init_gtk_sourcelanguagemanager ();
    Init_gtk_sourcemark ();
    Init_gtk_sourceprintcompositor ();
    Init_gtk_sourcestylescheme ();
    Init_gtk_sourcestyleschememanager ();

}
