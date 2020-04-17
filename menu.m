
/*
 * Copyright (C) 1998,1999 David Stes.
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

#include <objc.h>
#include <stdlib.h>
#include <string.h>
#include <ocstring.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <Xm/Xm.h>
#include <Xm/CascadeB.h>
#include <Xm/PushB.h>
#include <Xm/Separator.h>
#include <Xm/RowColumn.h>
#undef Object
#undef String

#include "panic.h"
#include "document.h"
#include "menu.h"
#include <assert.h>

/* action procedures */

static void newap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [Document new];
}

static void openap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 1);
  [Document open:args[0]];
}

static void opendialogap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [[Document fromwidget:w] open];
}

static void closeap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [[Document fromwidget:w] close];
}

static void saveasap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [[Document fromwidget:w] saveas];
}

static void saveap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [[Document fromwidget:w] save];
}

static void revertap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [[Document fromwidget:w] revert];
}

static void printap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] print];
}

static void exitap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [Document closeall];
  exit(0); /* regardless of closeall success */
}

static void cutap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] cutclipboard];
}

static void copyap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] copyclipboard];
}

static void pasteap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] pasteclipboard];
}

static void deleteap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] delete];
}

static void selallap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] selectAll];
}

static void findap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] find];
}

static void enterselap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] enterselection];
}

static void findnextap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] findnext];
}

static void jumpap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  id doc = [Document fromwidget:w];
  [doc selectAndScroll];
  [doc update]; /* not needed, but ctrl-j can be used to force screen update */
}

static void findpreviousap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] findprevious];
}

static void replacedialogap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  replacedialog(w);
}

static void replaceap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
}

static void replaceallap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
}

static void rearrangeap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  assert(*nArgs == 0);
  [Document rearrange];
}

static void copyright(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  warndialog(w,
 "Copyright (C) 1998 David Stes.\n"
 "\n"
 "This program is free software; you can redistribute it and/or modify it\n"
 "under the terms of the GNU General Public License as published\n" 
 "by the Free Software Foundation; either version 2 of the License, or\n"
 "(at your option) any later version.\n"
 "\n"
 "This program is distributed in the hope that it will be useful,\n"
 "but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
 "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
 "GNU General Public License for more details.\n"
 "\n"
 "You should have received a copy of the GNU General Public License\n"
 "along with this program; if not, write to the Free Software\n"
 "Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.\n"
 );
}

static void romanap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeRoman];
}

static void swissap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeSwiss];
}

static void modernap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeModern];
}

static void plainap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makePlain];
}

static void italicap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeItalic];
}

static void boldap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeBold];
}

static void underlinedap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeUnderlined];
}

static void f9ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:9];
}

static void f10ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:10];
}

static void f11ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:11];
}

static void f12ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:12];
}

static void f14ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:14];
}

static void f18ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:18];
}

static void f20ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:20];
}

static void f24ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:24];
}

static void f36ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:36];
}

static void f48ap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  [[Document fromwidget:w] makeFontsize:48];
}

static void nyiap(Widget w, XEvent *event, char **args, Cardinal *nArgs)
{
  fprintf(stderr,"Not yet implemented.\n");
}

static XtActionsRec appactions[] = {
  {"new", newap},
  {"open", openap},
  {"open_dialog", opendialogap},
  {"close", closeap},
  {"save", saveap},
  {"save_as", saveasap},
  {"save_as_dialog", saveasap},
  {"revert_to_saved", revertap},
  {"print", printap},
  {"exit", exitap},
  {"cut_clipboard", cutap},
  {"copy_clipboard", copyap},
  {"paste_clipboard", pasteap},
  {"delete", deleteap},
  {"select_all", selallap},
  {"find", findap},
  {"enter_selection", enterselap},
  {"find_next", findnextap},
  {"find_previous", findpreviousap},
  {"replace", replaceap},
  {"replace_dialog", replacedialogap},
  {"replace_all", replaceallap},
  {"rearrange", rearrangeap},
  {"copyright", copyright},
  {"jump", jumpap},
  {"roman", romanap},
  {"swiss", swissap},
  {"modern", modernap},
  {"plain", plainap},
  {"italic", italicap},
  {"bold", boldap},
  {"underlined", underlinedap},
  {"f9", f9ap},
  {"f10", f10ap},
  {"f11", f11ap},
  {"f12", f12ap},
  {"f14", f14ap},
  {"f18", f18ap},
  {"f20", f20ap},
  {"f24", f24ap},
  {"f36", f36ap},
  {"f48", f48ap},
  {"nyi", nyiap},
};

void addactions(XtAppContext context)
{
  XtAppAddActions(context,appactions,XtNumber(appactions));
}

static Widget menubutton(Widget parent,char *name,char *label,char mnemonic,XtCallbackProc callback,void *cbarg)
{
  XmString s;
  Widget button;
  button = XtVaCreateWidget(name,xmPushButtonWidgetClass,parent, 
	  XmNlabelString,s=XmStringCreateSimple(label),
	  XmNmnemonic,mnemonic,NULL);
  XtAddCallback(button,XmNactivateCallback,callback,cbarg);
  XmStringFree(s);
  XtManageChild(button);
  return button;
}

static Widget menu(Widget parent, char *name, char *label,char mnemonic, Widget *cascaderef)
{
  XmString s;
  Widget menu, cascade;
  menu = XmCreatePulldownMenu(parent,name,NULL,0);
  cascade = XtVaCreateWidget(name, xmCascadeButtonWidgetClass, parent, 
      XmNlabelString, s=XmStringCreateSimple(label),
      XmNsubMenuId, menu, 0);
  XmStringFree(s);
  if (mnemonic != 0)
      XtVaSetValues(cascade, XmNmnemonic, mnemonic, 0);
  XtManageChild(cascade);
  if (cascaderef != NULL) {
      *cascaderef = cascade;
  }
  return menu;
}

static Widget menuseparator(Widget parent, char *name)
{
  Widget button;
  button = XmCreateSeparator(parent, name, NULL, 0);
  XtManageChild(button);
  return button;
}

static void doaction(Widget w,XtPointer clientdata,XtPointer calldata)
{
  Widget lf,m;
  m  = XmGetPostedFromWidget(XtParent(w));
  lf = [[Document fromwidget:m] lastfocus];
  if (lf) {
    XtCallActionProc(lf, (char *)clientdata,((XmAnyCallbackStruct *)calldata)->event, NULL, 0);
  }
}

static void windowmenucb(Widget w,XtPointer clientdata,XtPointer calldata)
{
  id document = (id)clientdata;
  [document updatewindowsmenu];
}

void emptywindowsmenu(Widget windowsmenu)
{
  int i,nitems;
  WidgetList items;

  XtVaGetValues(windowsmenu, XmNchildren, &items, XmNnumChildren, &nitems,0);

  for(i=3;i<nitems;i++) {
    XtUnmanageChild(items[i]);
    XtDestroyWidget(items[i]);
  }
}

static void raisecb(Widget w,XtPointer clientdata,XtPointer calldata)
{
  id document = (id)clientdata;
  [document raise];
}

Widget windowbutton(Widget parent,id document)
{
  Widget btn;
  XmString s;
  char *title = [document filename];
  
  btn = XtVaCreateManagedWidget("win", xmPushButtonWidgetClass, parent, XmNlabelString, s=XmStringCreateSimple(title),NULL);
  XtAddCallback(btn, XmNactivateCallback, raisecb, document);
  XmStringFree(s);

  return btn;
}

Widget newmenubar(Widget parent,id document)
{
  Widget mbar,pane,cascade;

  mbar = XmCreateMenuBar(parent, "menubar", NULL, 0);

  pane = menu(mbar,"filemenu","File",0,NULL);
  menubutton(pane,"new","New",'N',doaction,"new");
  menubutton(pane,"open","Open...",'O',doaction,"open_dialog");
  menuseparator(pane,"sep0");
  menubutton(pane,"close","Close",'C',doaction,"close");
  menubutton(pane,"save","Save",'S',doaction,"save");
  menubutton(pane,"saveas","Save As...",'A',doaction,"save_as");
  menubutton(pane,"revert","Revert to Saved",'R',doaction,"revert_to_saved");
  menuseparator(pane,"sep1");
  menubutton(pane,"print","Print...",'P',doaction,"print");
  menuseparator(pane,"sep2");
  menubutton(pane,"exit","Exit",'x',doaction,"exit");

  pane = menu(mbar,"editmenu","Edit",0,NULL);
  menubutton(pane,"cut","Cut",'t',doaction,"cut_clipboard");
  menubutton(pane,"copy","Copy",'C',doaction,"copy_clipboard");
  menubutton(pane,"paste","Paste",'P',doaction,"paste_clipboard");
  menubutton(pane,"delete","Delete",'D',doaction,"delete");
  menuseparator(pane,"sep3");
  menubutton(pane,"selectall","Select All",'A',doaction,"select_all");

  pane = menu(mbar,"searchmenu","Search",0,NULL);
  menubutton(pane,"find","Find...",'F',doaction,"find");
  menubutton(pane,"entersel","Enter Selection",'E',doaction,"enter_selection");
  menubutton(pane,"findnext","Find Next",'N',doaction,"find_next");
  menubutton(pane,"findprevious","Find Previous",'P',doaction,"find_previous");
  menubutton(pane,"replacedialog","Replace With...",'W',doaction,"replace_dialog");
  menubutton(pane,"replace","Replace",'R',doaction,"replace");
  menubutton(pane,"jump","Jump To Selection",'J',doaction,"jump");

  pane = menu(mbar,"fontmenu","Font",0,NULL);
  menubutton(pane,"roman","Roman",'R',doaction,"roman");
  menubutton(pane,"swiss","Swiss",'S',doaction,"swiss");
  menubutton(pane,"modern","Modern",'M',doaction,"modern");

  pane = menu(mbar,"sizemenu","Size",0,NULL);
  menubutton(pane,"size9","9",0,doaction,"f9");
  menubutton(pane,"size10","10",0,doaction,"f10");
  menubutton(pane,"size11","11",0,doaction,"f11");
  menubutton(pane,"size12","12",0,doaction,"f12");
  menubutton(pane,"size14","14",0,doaction,"f14");
  menubutton(pane,"size18","18",0,doaction,"f18");
  menubutton(pane,"size20","20",0,doaction,"f20");
  menubutton(pane,"size24","24",0,doaction,"f24");
  menubutton(pane,"size36","36",0,doaction,"f36");
  menubutton(pane,"size48","48",0,doaction,"f48");
  menuseparator(pane,"sep4");
  menubutton(pane,"smaller","Smaller",'S',doaction,"nyi");
  menubutton(pane,"larger","Larger",'L',doaction,"nyi");

  pane = menu(mbar,"stylemenu","Style",0,NULL);
  menubutton(pane,"plain","Plain",'P',doaction,"plain");
  menuseparator(pane,"sep5");
  menubutton(pane,"bold","Bold",'B',doaction,"bold");
  menubutton(pane,"italic","Italic",'I',doaction,"italic");
  menubutton(pane,"underlined","Underlined",'U',doaction,"underlined");

  pane = menu(mbar,"windowsmenu","Windows",0,&cascade);
  [document setwindowsmenu:pane];
  XtAddCallback(cascade, XmNcascadingCallback, windowmenucb,document);
  menubutton(pane,"rearrange","Rearrange",'R',doaction,"rearrange");
  menubutton(pane,"copyright","About Richtext...",'G',doaction,"copyright");
  menuseparator(pane,"sep6");

  return mbar;
}

