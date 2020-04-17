
/*
 * Copyright (C) 1998 David Stes.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published 
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#define DLGOK 1
#define DLGCANCEL 2

void warn(char *format,...);
void panic(char *format,...);
void centerdialog(Widget dialog);
void warndialog(Widget parent,char *format,...);
extern id selectedname;
int runfiledialog(Widget parent,char *prompt);
int yesnodialog(Widget parent,char *format,...);
extern id printcmd;
extern id findstring;
extern id replacestring;
int finddialog(Widget parent);
int replacedialog(Widget parent);
int printdialog(Widget parent);

