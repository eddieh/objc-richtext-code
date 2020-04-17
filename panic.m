
/*
 * Copyright (C) 1998,99 David Stes.
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

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <objc.h>
#include <ocstring.h>
#include <assert.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <X11/Shell.h>
#include <Xm/Xm.h>
#include <Xm/MainW.h>
#include <Xm/PanedW.h>
#include <Xm/DialogS.h>
#include <Xm/MessageB.h>
#include <Xm/SelectioB.h>
#include <Xm/FileSB.h>
#include <Xm/Text.h>
#include <Xm/ToggleB.h>
#include <Xm/RowColumn.h>
#undef Object
#undef String

#include "main.h"
#include "panic.h"
#include "richtext.h"

void panic(char *format,...)
{
  va_list ap;
  va_start(ap,format);
  vfprintf(stderr,format,ap);
  va_end(ap);
  abort();
}

void warn(char *format,...)
{
  va_list ap;
  va_start(ap,format);
  vfprintf(stderr,format,ap);
  va_end(ap);
}

static int okflag=0;
static int cancelflag=0;

static void okcallback(Widget w,XtPointer clientdata,XtPointer calldata)
{
  okflag++;
}

static void cancelcallback(Widget w,XtPointer clientdata,XtPointer calldata)
{
  cancelflag++;
}

void centerdialog(Widget dialog)
{
  Window root,child;
  unsigned int mask;
  Boolean mappedmanaged;
  int x, y, mx, my, wx, wy;
  unsigned int w, h, bw, depth;
  Widget shell = XtParent(dialog);

  XtVaGetValues(shell, XmNmappedWhenManaged, &mappedmanaged, 0);
  XtVaSetValues(shell, XmNmappedWhenManaged, False, 0);

  XtManageChild(dialog);

  XQueryPointer(XtDisplay(shell),XtWindow(shell),&root,&child,&x,&y,&wx,&wy,&mask);

  XGetGeometry(XtDisplay(shell),XtWindow(shell),&root,&wx,&wy,&w,&h,&bw,&depth);

  w += 2 * bw;
  h += 2 * bw;

  mx = XtScreen(shell)->width - w;
  my = XtScreen(shell)->height - h;

  x -= w/4;
  y -= h/2;

  if (x < 0) x = 0;if (x > mx) x = mx;
  if (y < 0) y = 0;if (y > my) y = my;

  XtVaSetValues(shell, XmNx, x, XmNy, y, NULL);

  XtMapWidget(shell);

  XtVaSetValues(shell, XmNmappedWhenManaged, mappedmanaged, 0);
}

void warndialog(Widget parent,char *format,...)
{
  int ac = 0;
  XmString s;
  va_list ap;
  Arg args[256];
  char msg[8192];
  Widget dialog, dialogshell;

  va_start(ap,format);
  vsprintf(msg,format,ap);
  va_end(ap);

  s = XmStringCreateLtoR (msg,XmSTRING_DEFAULT_CHARSET);

  XtSetArg (args[ac], XmNmessageString, s);ac++;
  XtSetArg (args[ac], XmNdialogType, XmDIALOG_WARNING);ac++;

  dialogshell = XmCreateDialogShell(parent,"Warning",NULL,0);
  dialog = XmCreateMessageBox(dialogshell,"msgbox",args,ac);

  XtAddCallback (dialog, XmNokCallback,okcallback,NULL);
  XtUnmanageChild(XmMessageBoxGetChild(dialog,XmDIALOG_CANCEL_BUTTON));
  XtUnmanageChild(XmMessageBoxGetChild(dialog,XmDIALOG_HELP_BUTTON));
  
  okflag = 0;
  centerdialog(dialog);
  while (okflag == 0) {
    XtAppProcessEvent (XtWidgetToApplicationContext(dialog), XtIMAll);
  }

  XtDestroyWidget(dialog);
  XmStringFree(s);
}

int yesnodialog(Widget parent,char *format,...)
{
  int ac = 0;
  va_list ap;
  Arg args[256];
  char msg[8192];
  XmString s,nos,yess;
  Widget dialog, dialogshell;

  va_start(ap,format);
  vsprintf(msg,format,ap);
  va_end(ap);

  s = XmStringCreateLtoR (msg,XmSTRING_DEFAULT_CHARSET);
  yess = XmStringCreateLtoR ("Yes",XmSTRING_DEFAULT_CHARSET);
  nos = XmStringCreateLtoR ("No",XmSTRING_DEFAULT_CHARSET);

  XtSetArg (args[ac], XmNmessageString, s);ac++;
  XtSetArg (args[ac], XmNdialogType, XmDIALOG_WARNING);ac++;
  XtSetArg (args[ac], XmNokLabelString, yess);ac++;
  XtSetArg (args[ac], XmNcancelLabelString, nos);ac++;

  dialogshell = XmCreateDialogShell(parent,"Warning",NULL,0);
  dialog = XmCreateMessageBox(dialogshell,"msgbox",args,ac);

  XtAddCallback (dialog, XmNokCallback,okcallback,NULL);
  XtAddCallback (dialog, XmNcancelCallback,cancelcallback,NULL);
  XtUnmanageChild(XmMessageBoxGetChild(dialog,XmDIALOG_HELP_BUTTON));
  
  okflag = 0;
  cancelflag = 0;
  centerdialog(dialog);
  while (okflag == 0 && cancelflag==0) {
    XtAppProcessEvent (XtWidgetToApplicationContext(dialog), XtIMAll);
  }

  XtDestroyWidget(dialog);
  XmStringFree(s);
  XmStringFree(nos);
  XmStringFree(yess);

  return (okflag)?YES:NO;
}

id selectedname;

int runfiledialog(Widget parent,char *prompt)
{
  int r;
  int ac = 0;
  Arg args[256];
  Widget dialog, dialogshell;
  XmString s1,s3;

  s1 = XmStringCreateLtoR ("*.rtf",XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNdirMask, s1);ac++;
  s3 = XmStringCreateLtoR (prompt,XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNselectionLabelString, s3);ac++;

  dialogshell = XmCreateDialogShell(parent,"Select File",NULL,0);
  dialog = XmCreateFileSelectionDialog(dialogshell,"Select File",args,ac);

  XtAddCallback (dialog, XmNokCallback,okcallback,NULL);
  XtAddCallback (dialog, XmNcancelCallback,cancelcallback,NULL);
  XtUnmanageChild(XmFileSelectionBoxGetChild(dialog,XmDIALOG_HELP_BUTTON));
  
  okflag = 0;
  cancelflag = 0;
  centerdialog(dialog);
  while (okflag == 0 && cancelflag == 0) {
    XtAppProcessEvent (XtWidgetToApplicationContext(dialog), XtIMAll);
  }

  if (okflag) {
    char *p; 
    XmString t;
    XtVaGetValues(dialog, XmNdirSpec,&t,NULL);
    XmStringGetLtoR(t, XmSTRING_DEFAULT_CHARSET, &p);
    selectedname = [String str:p];
    XmStringFree(t);
    r = DLGOK;
  } else {
    r = DLGCANCEL;
  }

  XtDestroyWidget(dialog);
  XmStringFree(s1);
  XmStringFree(s3);
  return r;
}

static int textdialog(Widget parent,char *prompt,id *what)
{
  int r;
  int ac = 0;
  Time tstamp;
  Arg args[256];
  XmString s1,s2;
  Widget dialog, dialogshell, textw;
  char *fs = (*what)?[(*what) str]:"";

  s1 = XmStringCreateLtoR (prompt,XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNselectionLabelString, s1);ac++;
  s2 = XmStringCreateLtoR (fs,XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNtextString, s2);ac++;

  dialogshell = XmCreateDialogShell(parent,prompt,NULL,0);
  dialog = XmCreatePromptDialog(dialogshell,prompt,args,ac);

  XtAddCallback (dialog, XmNokCallback,okcallback,NULL);
  XtAddCallback (dialog, XmNcancelCallback,cancelcallback,NULL);

  XtUnmanageChild(XmSelectionBoxGetChild(dialog,XmDIALOG_HELP_BUTTON));
  XtUnmanageChild(XmSelectionBoxGetChild(dialog,XmDIALOG_APPLY_BUTTON));

  okflag = 0;
  cancelflag = 0;
  centerdialog(dialog);

  textw = XmSelectionBoxGetChild(dialog,XmDIALOG_TEXT);
  assert(textw);
  tstamp = XtLastTimestampProcessed(maindisplay);
  XmTextSetSelection(textw,0,XmTextGetLastPosition(textw),tstamp);
  
  while (okflag == 0 && cancelflag == 0) {
    XtAppProcessEvent (XtWidgetToApplicationContext(dialog), XtIMAll);
  }

  if (okflag) {
    char *p; 
    XmString t;
    XtVaGetValues(dialog,XmNtextString,&t,0);
    XmStringGetLtoR(t, XmSTRING_DEFAULT_CHARSET, &p);
    if (*what) [*what free];
    *what = [String str:p];
    XmStringFree(t);
    r = DLGOK;
  } else {
    r = DLGCANCEL;
  }

  XtDestroyWidget(dialog);
  XmStringFree(s1);
  XmStringFree(s2);
  return r;
}

id printcmd;
id findstring;
id replacestring;

int finddialog(Widget w)
{
  return textdialog(w,"Find:",&findstring);
}

int replacedialog(Widget w)
{
  return textdialog(w,"Replace with:",&replacestring);
}

static Widget radiobutton(Widget parent,char *name,char *label,char mnemonic,XtCallbackProc callback,void *cbarg)
{
  XmString s;
  Widget button;
  button = XtVaCreateWidget(name,xmToggleButtonWidgetClass,parent, 
	  XmNlabelString,s=XmStringCreateSimple(label),
	  XmNmnemonic,mnemonic,NULL);
  XtAddCallback(button,XmNvalueChangedCallback,callback,cbarg);
  XmStringFree(s);
  XtManageChild(button);
  return button;
}

static void doradio(Widget w,XtPointer clientdata,XtPointer calldata)
{
  XmToggleButtonCallbackStruct *tbs=(XmToggleButtonCallbackStruct*)calldata;
  dbg("doradio %i\n",(int)clientdata);
  if (tbs->set) {
    papersize = (int)clientdata;
  }
  assert(papersize == PSIZE_A4 || papersize == PSIZE_USLetter);
}

int printdialog(Widget parent)
{
  int r;
  int ac = 0;
  Time tstamp;
  Arg args[256];
  XmString s1,s2;
  id *what = &printcmd;
  char *prompt = "Print command:";
  Widget b1, b2, radio, dialog, dialogshell, textw;
  char *fs = (printcmd)?[printcmd str]:"";

  s1 = XmStringCreateLtoR (prompt,XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNselectionLabelString, s1);ac++;
  s2 = XmStringCreateLtoR (fs,XmSTRING_DEFAULT_CHARSET);
  XtSetArg (args[ac], XmNtextString, s2);ac++;

  dialogshell = XmCreateDialogShell(parent,prompt,NULL,0);
  dialog = XmCreatePromptDialog(dialogshell,prompt,args,ac);

  XtAddCallback (dialog, XmNokCallback,okcallback,NULL);
  XtAddCallback (dialog, XmNcancelCallback,cancelcallback,NULL);

  XtUnmanageChild(XmSelectionBoxGetChild(dialog,XmDIALOG_HELP_BUTTON));
  XtUnmanageChild(XmSelectionBoxGetChild(dialog,XmDIALOG_APPLY_BUTTON));

  ac = 0;
  radio = XmCreateRowColumn(dialog,"radiobox",NULL,0); 
  XtSetArg (args[ac], XmNorientation, XmHORIZONTAL);ac++;
  XtSetArg (args[ac], XmNradioBehavior, True);ac++;
  XtSetArg (args[ac], XmNradioAlwaysOne, True);ac++;
  XtSetValues(radio,args, ac);
  b1 = radiobutton(radio,"a4","A4",0,doradio,(void*)PSIZE_A4);
  b2 = radiobutton(radio,"us","US/Letter",0,doradio,(void*)PSIZE_USLetter);

  ac = 0;
  switch (papersize) {
    case PSIZE_A4 :
       XmToggleButtonSetState(b1,True,False);
       XtSetArg (args[ac], XmNmenuHistory, b1);ac++;
       break;
    case PSIZE_USLetter :
       XmToggleButtonSetState(b2,True,False);
       XtSetArg (args[ac], XmNmenuHistory, b1);ac++;
       break;
    default :
       break;
  }
  XtSetValues(radio,args, ac);
  XtManageChild(radio);

  okflag = 0;
  cancelflag = 0;
  centerdialog(dialog);

  while (okflag == 0 && cancelflag == 0) {
    XtAppProcessEvent (XtWidgetToApplicationContext(dialog), XtIMAll);
  }

  if (okflag) {
    char *p; 
    XmString t;
    XtVaGetValues(dialog,XmNtextString,&t,0);
    XmStringGetLtoR(t, XmSTRING_DEFAULT_CHARSET, &p);
    if (*what) [*what free];
    *what = [String str:p];
    XmStringFree(t);
    r = DLGOK;
  } else {
    r = DLGCANCEL;
  }

  XtDestroyWidget(dialog);
  XmStringFree(s1);
  XmStringFree(s2);
  return r;
}

