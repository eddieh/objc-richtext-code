
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

#include <stdlib.h>
#include <Object.h>
#include <ocstring.h>
#include <sortcltn.h>
#include <rectangl.h>
#include <sequence.h>
#include <assert.h>
#include <stdarg.h>
#include <limits.h>
#include <errno.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <X11/Shell.h>
#include <X11/cursorfont.h>
#if 0
#include <X11/keysymdef.h>
#endif
#include <Xm/Xm.h>
#include <Xm/MainW.h>
#include <Xm/ScrollBar.h>
#include <Xm/Protocols.h>
#include <Xm/CutPaste.h>
#include "rtfwidget.h"
#undef Object
#undef String

#include "document.h" /* subclass of Object */
#include "main.h"
#include "menu.h"
#include "richtext.h"
#include "panic.h"
#include <ordcltn.h>
#include <paragrph.h>
#include "charblk.h"
#include <txtattr.h> 
#include "plain.h" 
#include "boldface.h" 
#include "italic.h" 
#include "underlined.h" 
#include "fontchange.h" 
#include "fontsizechange.h" 
#include "richfont.h"

#include "richtext.xbm"

#define Object XtObject
/* XtWindow() and XtDisplay are casting to Object */
static Window getxwindow(void* w) { return XtWindow((Widget)w); }
static Display* getxdisplay(void* w) { return XtDisplay((Widget)w); }
#undef Object

static id documents;

@implementation Document 

+ initialize
{
  rtfwidgetinitialize();
  documents = [OrdCltn new];
  papersize = PSIZE_A4;
#ifndef LPCMD
#define LPCMD "lpr -h -#1 -P lp"
#endif
  printcmd = [String str:LPCMD];
  return self;
}

+ documents
{
  return documents;
}

+ rearrange
{
  int i;
  int n = [documents size];

  for(i=0;i<n;i++) {
    id doc = [documents at:i];
    [doc raise];
  }

  return self;
}

static void scrollcb(Widget w, XtPointer clientdata, XtPointer calldata)
{
  int newvalue = ((XmScrollBarCallbackStruct *)calldata)->value;
  [(id)clientdata scroll:newvalue];
}

- setibeamcursor
{
  Cursor cursor = XCreateFontCursor(getxdisplay(textwidget),XC_xterm);
  XDefineCursor(getxdisplay(textwidget),getxwindow(textwidget),cursor);
  return self;
}

- setwaitcursor
{
  Cursor cursor = XCreateFontCursor(getxdisplay(textwidget),XC_watch);
  XDefineCursor(getxdisplay(textwidget),getxwindow(textwidget),cursor);
  return self;
}

static void deleteproc(Widget w,caddr_t clientdata,caddr_t calldata)
{
  [(id)clientdata close];
}

- setwmcallbacks
{
  Atom xa = XmInternAtom(maindisplay,"WM_DELETE_WINDOW",True);
  XmAddWMProtocolCallback(shell,xa,(XtCallbackProc)deleteproc,(caddr_t)self);
  return self;
}

- realize 
{
  int ac = 0;
  Arg al[20];
  Pixmap icon;
  char *nm = [filename str];

  XtSetArg(al[ac], XmNtitle, nm); ac++;
  XtSetArg(al[ac], XmNdeleteResponse, XmDO_NOTHING); ac++;
  XtSetArg(al[ac], XmNiconName, nm); ac++;

  shell = XtAppCreateShell(NULL, APP_CLASS,applicationShellWidgetClass, maindisplay, al, ac);

  /* store self in userData  (see +fromwidget:) */
  XtSetArg(al[ac], XmNuserData, (XtPointer)self); ac++;
  XtSetArg(al[ac], XmNspacing, 0); ac++;

  /* set callback for WM close button */
  [self setwmcallbacks];

  mainw = XmCreateMainWindow(shell, "main", al, ac);
  XtManageChild(mainw);

  menubar = newmenubar(mainw,self);
  XtManageChild(menubar);

  scrollbar = XtVaCreateManagedWidget("scrollbar",xmScrollBarWidgetClass,mainw,XmNorientation,XmVERTICAL,XmNrepeatDelay,10,0); 
  XtAddCallback(scrollbar, XmNdragCallback, scrollcb, (XtPointer)self);
  XtAddCallback(scrollbar, XmNvalueChangedCallback, scrollcb, (XtPointer)self);
 
  textwidget = XtVaCreateManagedWidget("richtext",rtfWidgetClass,mainw,rtfNrichtext,richtext,rtfNscrollbar,scrollbar,0); 

  XmMainWindowSetAreas(mainw,menubar,NULL,NULL,scrollbar,textwidget);

  lastfocus = textwidget;

  [documents add:self];

  XtRealizeWidget(shell);

  [self setmodified:NO]; /* because resize() may have set modified to YES */

  icon = XCreateBitmapFromData(getxdisplay(shell),getxwindow(shell),(char*)richtext_bits,richtext_width,richtext_height);
  ac = 0;
  XtSetArg(al[ac], XtNiconPixmap, icon); ac++;
  XtSetValues(shell, al, ac);

  [self setibeamcursor];
  return self;
}

+ new
{
  id doc = [super new];
  id rt = [Richtext new];
  [rt adobefonts];
  [rt addnewline];
  [doc richtext:rt];
  [doc setuntitledname];
  return [doc realize];
}

static void delayedopen(XtPointer clientdata,XtIntervalId *timer)
{
  [documents elementsPerform:@selector(setwaitcursor)];
  [Document open:[selectedname str]];
  selectedname = [selectedname free];
  [documents elementsPerform:@selector(setibeamcursor)];
}

- open
{
  if (DLGOK == runfiledialog(shell,"Open File:")) {
    assert(selectedname != nil);
    XtAppAddTimeOut(maincontext,1,delayedopen,NULL);
  }
  return self;
}

- richtext:obj
{
  richtext=obj;
  return self;
}

- richtext
{
  return richtext;
}

- open:(char*)fn
{
  FILE *f;
  char *what;

  f = fopen(fn,"r");
  if (!f) {
    what = strerror(errno);
    goto err;
  }

  [self richtext:[Richtext new]];
  if (![richtext readrtf:f]) {
    what = [richtext errormsg];
    goto err;
  }

  fclose(f);
  [self setfilename:fn];
  [self realize];
  return self;

err:
  [self setuntitledname];
  [self realize];
  warndialog([self lastfocus],"Can't open %s.\n\n%s.",fn,what);
  if (f) fclose(f);
  return self;
}

+ open:(char*)fn
{
  return [[super new] open:fn];
}

+ fromwidget:(Widget)w
{
  id doc;

  while (1) {
    Widget parent = XtParent(w);
    if (parent == NULL) return nil;
    if (XtClass(parent) == applicationShellWidgetClass) break;
    w = parent;
  }

  XtVaGetValues(w, XmNuserData, &doc, 0);
  return doc;
}

+ fromfilename:(char*)fn 
{
  int i,n;
  for(i=0,n=[documents size];i<n;i++) {
    id doc = [documents at:i];
    if (!strcmp([doc filename],fn)) {
      return doc;
    }
  }
  return nil;
}

- revert
{
  if (!untitled) {
    id n,t = [filename copy];
    [self raise];
    if (modified) {
      char *msg = "Do you really want to revert and close %s WITHOUT saving changes ?";
      if (!yesnodialog(shell,msg,[self filename])) {
        return self;
      }
    }
    [self free];
    n = [Document open:[t str]];
    [t free];
    return n;
  } else {
    return self;
  }
}

- reallyfree
{
  if (richtext) richtext = [richtext free];
  return [super free];
}

static void delayedfree(XtPointer clientdata,XtIntervalId *timer)
{
  [(id)clientdata reallyfree];
}

- free
{
  [documents remove:self];

  [self xtdisownsel];
  if (blinktimer) [self stopBlink];
  if (autoscrolltimer) [self stopAutoscroll];

  XtVaSetValues(textwidget,rtfNrichtext,nil,NULL);
  XtRemoveCallback(scrollbar,XmNdragCallback, scrollcb,NULL);
  XtRemoveCallback(scrollbar,XmNvalueChangedCallback, scrollcb,NULL);
  XtDestroyWidget(shell);
 
  XtAppAddTimeOut(maincontext,1,delayedfree,self);
  return nil;
}

static Atom fetchatom(Widget w,char* name)
{
  Atom a;
  XrmValue source, dest;

  source.size = strlen(name)+1;
  source.addr = name;
  dest.size = sizeof(Atom);
  dest.addr = (caddr_t) &a;

  XtConvertAndStore(w, XtRString, &source, XtRAtom, &dest);
  return a;
}

static Boolean deliverxtsel(Widget w,Atom *selection,Atom *target,Atom *type,XtPointer *value,unsigned long *length,int *format)
{
  static Atom targets;

  if (!targets) targets = fetchatom(w,"TARGETS");

  if (*target == targets) {
    /* if we're asked what types we support, say XA_STRING */
    *type = XA_ATOM;
    *value = (XtPointer)XtNew(Atom);
    *((Atom*)*value) = XA_STRING;
    *length = 1;
    *format = 32;
    return TRUE;
  }

  if (*target == XA_STRING) {
    id self = [Document fromwidget:w];
    id sel = [[self richtext] stringfrom:[self startblock] to:[self stopblock]];

    *type = XA_STRING;
    *value = (XtPointer)XtNewString([sel str]);
    *length = [sel size];
    *format = 8;

    [sel free];
    return TRUE;
  }

  return FALSE;
}

static void losextsel(Widget w,Atom *sel)
{
  /* nothing for the moment */
}

- xtownsel
{
  Time tstamp;
  [documents elementsPerform:@selector(xtdisownsel)];
  tstamp = XtLastTimestampProcessed(maindisplay);
  XtOwnSelection(textwidget,XA_PRIMARY,tstamp,deliverxtsel,losextsel,NULL);
  return self;
}

- xtdisownsel
{
  Time tstamp;
  tstamp = XtLastTimestampProcessed(maindisplay);
  XtDisownSelection(textwidget,XA_PRIMARY,tstamp);
  return self;
}

- motifcopy:s
{
  int r;
  long n;
  Time tstamp;
  XmString cliplabel;
  Window win = getxwindow(textwidget);
  Display *dpy = getxdisplay(textwidget);

  cliplabel = XmStringCreateSimple("Richtext");

  tstamp = XtLastTimestampProcessed(maindisplay);
  r=XmClipboardStartCopy(dpy,win,cliplabel,tstamp,NULL,NULL,&n);
  if (r!=ClipboardSuccess) goto fin;

  r=XmClipboardCopy(dpy,win,n,"STRING",[s str],[s size],0,NULL);
  if (r!=ClipboardSuccess) goto fin;

  XmClipboardEndCopy(dpy,win,n);

fin:
  XmStringFree(cliplabel);

  return self;
}

- copyclipboard
{
  if ([self properselection]) {
    id selstring;
    selstring = [richtext stringfrom:startblock to:stopblock];
    dbg("copying %s\n",[selstring str]);

    /* this is a bit complicated by the XA_PRIMARY nonsense and the Motif
     * Clipboard.  deliver selection immediately to Motif so motif copy/paste
     * should work, and announce we're ready to deliver Xt selections
     */

    [self motifcopy:selstring];
    [self xtownsel];

    [selstring free];
  }

  return self;
}

- cutclipboard
{
  [self copyclipboard];
  [self delete];
  return self;
}

- pasteclipboard
{
  id s;
  char*b;
  long n = 0;
  unsigned long len,rlen;
  Window win = getxwindow(textwidget);
  Display *dpy = getxdisplay(textwidget);

  if (XmClipboardInquireLength(dpy,win,"STRING",&len) != ClipboardSuccess || len == 0) return self;

  s = [String new:len+1];
  b = [s str];
  if (XmClipboardRetrieve(dpy,win,"STRING",b,len,&rlen,&n) != ClipboardSuccess || rlen == 0) {
    [s free];
    return self;
  } else {
    b[rlen] = '\0';
  }

  [self zapSelection:b count:rlen];
  [s free];
  return self;
}

- delete
{
  [self zapSelection:"" count:0];
  return self;
}

- setselectedfilename
{
  int n;
  char *s = [selectedname str];
  assert(selectedname != nil && s != NULL);
  if ((n=strlen(s)) <= 4 || strcmp(s+n-4,".rtf")) {
    [selectedname concatSTR:".rtf"];
  }
  [self setfilename:[selectedname str]];
  selectedname = [selectedname free];
  return self;
}

- saveas
{
  if (DLGOK == runfiledialog(shell,"Save as:")) {
    [self setuntitled:NO];
    [self setselectedfilename];
    [self save];
    [self setwindowtitle:[self filename]];
    return self;
  } else {
    return nil;
  }
}

- save
{
  if ([self isuntitled]) {
    return [self saveas];
  } else {
    FILE *f = fopen([self filename],"w");
    if (f) {
      [richtext writertf:f];
      fclose(f);
      [self setmodified:NO];
      return self;
    } else {
      char *what = strerror(errno);
      warndialog(shell,"Can't write to %s.\n\n%s.",[self filename],what);
      return nil;
    }
  }
}

- close
{
   [self raise];
   if (modified) {
     char *msg = "Do you want to save changes to %s ?";
     if (yesnodialog(shell,msg,[self filename])) {
       if (![self save]) return self;
     }
   }
   [self free];
   if ([documents size] == 0) exit(0);
   return nil;
}

+ closeall
{
  id doc;
  /* can't do a -do: or elementsPerform: because close modifies the cltn */
  while ((doc = [documents lastElement])) [doc close];
  return self;
}

- setwindowtitle:(char*)fn
{
  XtVaSetValues(shell,XmNtitle,fn,XmNiconName,fn,0);
  return self;
}

- setfilename:(char*)fn
{
  filename = [String str:fn];
  return self;
}

- setuntitledname
{
  int i;
  char buf[256];

  [self setuntitled:YES];

  for(i=0;i<10000;i++) {
    if (i == 0) {
      sprintf(buf,"Untitled");
    } else {
      sprintf(buf,"Untitled-%i",i);
    }
    if (![isa fromfilename:buf]) { 
      return [self setfilename:buf];
    }
  }
  return [self error:"can't make unique filename"];
}

- (char*)filename
{
  return [filename str];
}

- (char*)path
{
  return [path str];
}

- (Widget)shell
{
  return shell;
}

- (Widget)lastfocus
{
  return lastfocus;
}

- (Widget)menubar
{
  return menubar;
}

- (int)compare:arg
{
  return strcmp([self filename],[arg filename]);
}

- updatewindowsmenu
{
  id docs,doc,sorted;
  emptywindowsmenu(windowsmenu);
  sorted = [[SortCltn new] addAll:documents];
  docs = [sorted eachElement];
  while ((doc=[docs next])) windowbutton(windowsmenu,doc);
  [docs free];
  [sorted free];
  return self;
}

- (Widget)windowsmenu
{
  return windowsmenu;
}

- setwindowsmenu:(Widget)w
{
  windowsmenu = w;
  return self;
}

- (BOOL)modified
{
  return modified;
}

- update
{
  [self recomputeSelection];
  [self updatescrollbar];
  refreshwidget((RtfWidget)textwidget);
  return self;
}

- (BOOL)havefocus
{
  return havefocus;
}

- havefocus:(BOOL)flag
{
  havefocus = flag;
  return self;
}

- setmodified:(BOOL)flag
{
  modified = flag;
  return self;
}

- scroll:(int)y
{
  int oldtop = [richtext top];

  if (y == oldtop) {
    return self;
  } else {
    int totalh = [richtext totalheight];
    int paperh = twips2points([richtext paperh]);
    int min = (totalh < paperh)?totalh:paperh;
    if (y >= 0 && y <= totalh - min) {
      [richtext top:y];
      scrollwidget((RtfWidget)textwidget,y - oldtop);
    } else if (y < 0) {
      if (oldtop != 0) {
	[richtext top:0];
	scrollwidget((RtfWidget)textwidget,-oldtop);
      }
    } else {
      if (oldtop != totalh - min) {
	[richtext top:totalh - min];
	scrollwidget((RtfWidget)textwidget,totalh - min - oldtop);
      }
    }
    return self;
  }
}

- updatescrollbar
{
  int ac = 0;
  Arg al[20];
  int oldtop = [richtext top];
  int totalh = [richtext totalheight];
  int paperh = twips2points([richtext paperh]);
  int min = (totalh<paperh)?totalh:paperh;
  int newtop = (oldtop+min <= totalh)?oldtop:totalh-min;

  [richtext top:newtop];

  if (totalh) {
    XtSetArg(al[ac], XmNmaximum,totalh); ac++;
    XtSetArg(al[ac], XmNsliderSize,min); ac++;
    XtSetArg(al[ac], XmNpageIncrement,min); ac++;
    XtSetArg(al[ac], XmNvalue,newtop); ac++;
  } else {
    XtSetArg(al[ac], XmNmaximum,1); ac++;
    XtSetArg(al[ac], XmNsliderSize,1); ac++;
    XtSetArg(al[ac], XmNpageIncrement,1); ac++;
    XtSetArg(al[ac], XmNvalue,0); ac++;
  }

  XtSetValues(scrollbar,al,ac);
  return self;
}

- (BOOL)readonly
{
  return readonly;
}

- setreadonly:(BOOL)flag
{
  readonly = flag;
  return self;
}

- (BOOL)isuntitled
{
  return untitled;
}

- setuntitled:(BOOL)flag
{
  untitled = flag;
  return self;
}

static void raisew(Display *d,Window w)
{
  XWindowAttributes wattr;
  XGetWindowAttributes(d,w,&wattr);
  if (wattr.map_state == IsViewable) {
    Time tstamp = XtLastTimestampProcessed(maindisplay);
    XSetInputFocus(d,w,RevertToParent,tstamp);
  }
  XMapRaised(d,w);
}

- raise
{
  raisew(getxdisplay(shell),getxwindow(shell));
  return self;
}

- startblock
{
  return startblock;
}

- stopblock
{
  return stopblock;
}

- startblock:a stopblock:b
{
  /* this forces the user to do control-c to copy */
  /* without this line, select would automatically (lazily) copy */
  /* but I don't like it */
  [self xtdisownsel];

  if (startblock) startblock = [startblock free];
  if (stopblock) stopblock = [stopblock free];
  startblock = a;
  stopblock = b;
  return self;
}

- reverseSelection
{
  if (!selectionshowing) [richtext selrectsfrom:startblock to:stopblock];
  hiliteselrects((RtfWidget)textwidget);
  if (selectionshowing) [richtext removeselrects];
  selectionshowing = !selectionshowing;
  return self;
}

- (BOOL)insertionpoint
{
  return startblock != nil && stopblock == nil;
}

- (BOOL)properselection
{
  return startblock != nil && stopblock != nil && [startblock compare:stopblock] <= 0;
}

static void autoscroll(XtPointer clientdata,XtIntervalId *timer)
{
  [(id)clientdata autoscroll];
}

- autoscroll
{
  int oldtop = [richtext top];
  int h = twips2points([richtext paperh]);

  if (mousey < 0) [self scroll:oldtop + mousey ];
  if (mousey > h) [self scroll:oldtop + mousey - h];

  if ([richtext top] != oldtop) [self updatescrollbar];

  autoscrolltimer = XtAppAddTimeOut(maincontext,getautoscroll(textwidget),autoscroll,self);
  return self;
}

- startAutoscroll
{
  if ([self insertionpoint]) [self stopBlink];
  if (!autoscrolltimer) [self autoscroll];
  return self;
}

- stopAutoscroll
{
  if (autoscrolltimer) {
    XtRemoveTimeOut(autoscrolltimer);
    autoscrolltimer = (XtIntervalId)NULL;
  }
  if ([self insertionpoint]) [self startBlink];
  return self;
}

static void blink(XtPointer clientdata,XtIntervalId *timer)
{
  [(id)clientdata blink];
}

- blink
{
  if (blinktimer) {
  assert([self insertionpoint]);
  selectionshowing = !selectionshowing;
  reverseinsertpoint((RtfWidget)textwidget,startblock);
  blinktimer = XtAppAddTimeOut(maincontext,getblinkrate(textwidget),blink,self);
  }
  return self;
}

- startBlink
{
  if (!blinktimer && [self insertionpoint]) {
    assert(selectionshowing == NO);
    blinktimer = XtAppAddTimeOut(maincontext,getblinkrate(textwidget),blink,self);
  }
  return self;
}

- stopBlink
{
  if (blinktimer && selectionshowing) {
    reverseinsertpoint((RtfWidget)textwidget,startblock);
    selectionshowing = NO;
  }
  if (blinktimer) {
    XtRemoveTimeOut(blinktimer);
    blinktimer = (XtIntervalId)NULL;
  }
  return self;
}

- zapSelection:(char*)s count:(int)n
{
  if ([self insertionpoint]) {
    int oldlinecount,newlinecount;
    [self deselect];
    oldlinecount = [[[richtext paralines] at:[startblock parindex]] size];
    [richtext atBlock:startblock insert:s count:n];
    newlinecount = [[[richtext paralines] at:[startblock parindex]] size];
    [self selectInvisiblyAt:[startblock parindex]:[startblock stringindex]+n];
    [self setmodified:YES];
    if (newlinecount == oldlinecount) {
      /* cheap but not always correct */
      refreshparagraph((RtfWidget)textwidget,[startblock parindex]);
    } else {
      [self update]; 
    }
    return [self select];
  }

  if ([self properselection]) {
    id attrs;
    int i = [startblock parindex];
    int j = [startblock stringindex];
    [self deselect];
    attrs = [[richtext attributesAtBlock:startblock] deepCopy];
    [richtext replaceFrom:startblock to:stopblock with:s count:n];
    [self selectInvisiblyFrom:i:j to:i:j+n];
    [richtext addAttributes:attrs fromblock:startblock toblock:stopblock];
    [attrs free];
    [self selectInvisiblyAt:i:j+n];
    [self update];
    [self setmodified:YES];
    return [self select];
  }

  XBell(maindisplay,100);
  return self;
}

- keydown:(XEvent*)event
{
  KeySym k;

  k = XtGetActionKeysym(event,NULL);

  if (k == NoSymbol) {
    XBell(maindisplay,100);
  } else {
    /* if (k == XK_hyphen) k = XK_minus; */
    if (k & 0xff00) {
    } else {
      char c = (char)(k);
      [self zapSelection:&c count:1];
    }
  }

  return self;
}

- newline
{
  [self zapSelection:"\n" count:1];
  return self;
}

- tabkey
{
  [self zapSelection:"\t" count:1];
  return self;
}

- movecursor:aBlock
{
  if (aBlock) {
    [self deselect];
    [self startblock:aBlock stopblock:nil];
    [self selectAndScroll];
  } else {
    XBell(maindisplay,100);
  }
  return self;
}

- cursorright
{
  id blk = nil;
  if ([self insertionpoint]) blk=[richtext blockAfter:startblock];
  if ([self properselection]) blk=[richtext blockAfter:stopblock];
  return [self movecursor:blk];
}

- cursorleft
{
  id blk = nil;
  if ([self insertionpoint]) blk=[richtext blockBefore:startblock];
  if ([self properselection]) blk=[richtext blockBefore:stopblock];
  return [self movecursor:blk];
}

- cursorup
{
  id blk = nil;
  if ([self insertionpoint]) blk=[richtext blockAbove:startblock];
  if ([self properselection]) blk=[richtext blockAbove:startblock];
  return [self movecursor:blk];
}

- cursordown
{
  id blk = nil;
  if ([self insertionpoint]) blk=[richtext blockBelow:startblock];
  if ([self properselection]) blk=[richtext blockBelow:stopblock];
  return [self movecursor:blk];
}

- backspace
{
  if ([self properselection]) {
    return [self delete];
  }
  if ([self insertionpoint]) {
     id b = [richtext blockBefore:startblock];
     [self startblock:b stopblock:[b copy]];
     return [self delete];
  } 
  XBell(maindisplay,100);
  return self;
}

static int numclicks;
static Time lasttime;

- mousedown:(XButtonEvent*)event
{
  id b;

  [self raise];
  
  b = [richtext charBlockAtPoint:event->x:event->y + [richtext top]];
  assert(b);

  [self deselect];

  if (event->time > lasttime + XtGetMultiClickTime(maindisplay)) {
    numclicks=1; 
  } else {
    numclicks++;
  }

  lasttime = event->time;

  switch (numclicks) {
    case 2  : 
      [self selectWordAt:b]; 
      break;
    case 3  : 
      [self selectLineAt:b];
      break;
    default :
      [self selectAt:b];
      break;
  }

  [self select];
  return self;
}

- shiftclick:(XButtonEvent*)event
{
  numclicks = 1;
  [self raise];
  return [self mousemoved:event];
}

- mousemoved:(XButtonEvent*)event
{
  id b;
  int h = twips2points([richtext paperh]);
  
  mousex = event->x;
  mousey = event->y;

  if (mousey < 0 || mousey > h) {
    [self startAutoscroll];
  } else {
    [self stopAutoscroll];
  }

  b = [richtext charBlockAtPoint:mousex:mousey + [richtext top]];
  assert(b);

  switch (numclicks) {
    case 2 : [self extendWordSelection:b];break;
    case 3 : [self extendLineSelection:b];break;
    default : [self extendSelection:b];break;
  }

  return self;
}

- mouseup:(XButtonEvent*)event
{
  if (pivotblock) pivotblock = [pivotblock free];
  [self stopAutoscroll];
  return self;
}

- wordbeginAt:aBlock
{
  int p,n;
  char *t,*delims;
  int pi = [aBlock parindex];
  int ci = [aBlock stringindex];
  
  delims = getworddelimiters(textwidget);
  n = [[[[richtext paragraphs] at:pi] text] size];
  t = [[[[richtext paragraphs] at:pi] text] str];

  if (n && strchr(delims,t[ci]) == NULL) {
    p = ci;
    while (p>0) if (strchr(delims,t[p])) {p++;break;} else p--;
    return [richtext charBlockForIndex:pi:p];
  }

  return nil;
}

- wordendAt:aBlock
{
  int q,n;
  char *t,*delims;
  int pi = [aBlock parindex];
  int ci = [aBlock stringindex];
  
  delims = getworddelimiters(textwidget);
  n = [[[[richtext paragraphs] at:pi] text] size];
  t = [[[[richtext paragraphs] at:pi] text] str];

  if (n && strchr(delims,t[ci]) == NULL) {
    q = ci;
    while (q<n) if (strchr(delims,t[q])) {q--;break;} else q++;
    if (q == n) q = n-1;
    return [richtext charBlockForIndex:pi:q];
  }

  return nil;
}

- selectWordAt:aBlock
{
  id a,b;
  
  if ((a = [self wordbeginAt:aBlock]) && (b = [self wordendAt:aBlock])) {
    [self startblock:a stopblock:b];
    [aBlock free];
  } else {
    [self selectAt:aBlock];
  }

  return self;
}

- linebeginAt:aBlock
{
  int n;
  int pi = [aBlock parindex];
  id pgs = [richtext paragraphs];

  if ((n = [pgs size]) && (pi < n)) {
    int m = [[[pgs at:pi] text] size];
    if (m) return [richtext charBlockForIndex:pi:0];
  }

  return nil;
}

- lineendAt:aBlock
{
  int n;
  int pi = [aBlock parindex];
  id pgs = [richtext paragraphs];

  if ((n = [pgs size]) && (pi < n)) {
    int m = [[[pgs at:pi] text] size];
    if (m) return [richtext charBlockForIndex:pi:m-1];
  }

  return nil;
}

- selectLineAt:aBlock
{
  id a,b;
  
  if ((a = [self linebeginAt:aBlock]) && (b = [self lineendAt:aBlock])) {
    [self startblock:a stopblock:b];
    [aBlock free];
  } else {
    [self selectAt:aBlock];
  }

  return self;
}

- selectAt:aBlock
{
  [self startblock:aBlock stopblock:nil]; 
  assert([self properselection] == NO);
  assert([self insertionpoint] == YES);
  return self;
}

- extendInsertion:b
{
  [self deselect];
  if ([startblock compare:b] <= 0) {
    [self startblock:[startblock copy] stopblock:b];
  } else {
    [self startblock:b stopblock:[startblock copy]];
  }
  return [self select];
}

- extendSelection:b
{
  if ([self insertionpoint]) {
    return [self extendInsertion:b]; 
  }

  if ([self properselection]) {

    if ([stopblock compare:b] == 0 || [startblock compare:b] == 0) {
      [b free];
      return self;
    }

    /* pivotblock will be nonnil, the first time we get here in a drag */
    if (pivotblock == nil) {
      if ([self insertionpoint]) {
	pivotblock = [startblock copy];
      }
      if ([self properselection]) {
	if ([stopblock compare:b] <= 0) {
	  pivotblock = [startblock copy];
	} else {
	  pivotblock = [stopblock copy];
	}
      }
    }
    
    if (dblbuf) disablertfflush((RtfWidget)textwidget);
    [self deselect];

    if ([pivotblock compare:b] <= 0) {
      [self startblock:[pivotblock copy] stopblock:b];
    } else {
      [self startblock:b stopblock:[pivotblock copy]];
    }

    if (dblbuf) enablertfflush((RtfWidget)textwidget);
    [self select];
  }

  return self;
}

- extendWordSelection:b
{
  id a;
  if ([pivotblock compare:b] <= 0) {
    a = [self wordendAt:b];
  } else {
    a = [self wordbeginAt:b];
  }
  if (a) {
    [b free];
    return [self extendSelection:a];
  } else {
    return [self extendSelection:b];
  }
}

- extendLineSelection:b
{
  id a;
  if ([pivotblock compare:b] <= 0) {
    a = [self lineendAt:b];
  } else {
    a = [self linebeginAt:b];
  }
  if (a) {
    [b free];
    return [self extendSelection:a];
  } else {
    return [self extendSelection:b];
  }
}


- select
{
  if ([self insertionpoint] && !blinktimer) return [self startBlink];

  if ([self properselection] && !selectionshowing) {
    return [self reverseSelection];
  }

  return self;
}

- deselect
{
  if ([self insertionpoint] && blinktimer) return [self stopBlink];

  if ([self properselection] && selectionshowing) {
    return [self reverseSelection]; 
  }

  return self;
}

- selectAndScroll
{
  id b = nil;

  if ([self properselection]) b = stopblock;
  if ([self insertionpoint]) b = startblock;

  if (b) {
    int y = [b top];
    int paperh = twips2points([richtext paperh]);

    /* this method should be called -scrollAndSelect */
   
    [self scroll:(y<paperh/4)?0:y-paperh/4];

    [self select];
    [self updatescrollbar];
  }

  return self;
}

- selectInvisiblyAt:(int)pi:(int)ci
{
  id a = [richtext charBlockForIndex:pi:ci];
  return [self startblock:a stopblock:nil];
}

- selectInvisiblyFrom:(int)pi:(int)ci to:(int)pj:(int)cj
{
  id a,b;

  a = [richtext charBlockForIndex:pi:ci];
  b = [richtext charBlockForIndex:pj:cj];

  return [self startblock:a stopblock:b];
}

static void delayedfind(XtPointer clientdata,XtIntervalId *timer)
{
  [(id)clientdata findnext];
}

- find
{
  if (finddialog(shell) == DLGOK) {
    XtAppAddTimeOut(maincontext,1,delayedfind,self);
  }
  return self;
}

- enterselection
{
  if ([self properselection]) {
    if (findstring) [findstring free];
    findstring = [richtext stringfrom:startblock to:stopblock];
  }
  return self;
}

- findnext
{
  char *s,*t;
  id paragraphs = [richtext paragraphs];
  int len,i,n = [paragraphs size];
  char *fs = [findstring str];

  len = (fs)?strlen(fs):0;

  if (n && len) {

    if ([self properselection]) {
      i = [stopblock parindex];
      s = [[[paragraphs at:i] text] str];
      t = s + [stopblock stringindex] + 1;
    } else if ([self insertionpoint]) {
      i = [startblock parindex];
      s = [[[paragraphs at:i] text] str];
      t = s + [startblock stringindex];
    } else {
      i = 0;
      s = [[[paragraphs at:i] text] str];
      t = s;
    }

    while (1) {
      char *f;
      if ((f=strstr(t,fs))) {
	return [self selectFrom:i:f-s to:i:f-s+len-1];
      }
      if (++i < n) t = (s = [[[paragraphs at:i] text] str]); else break;
    }
  }

  XBell(maindisplay,100);
  return self;
}

- findprevious
{
  char *s,*t;
  id paragraphs = [richtext paragraphs];
  int len,i,n = [paragraphs size];
  char *fs = [findstring str];

  len = (fs)?strlen(fs):0;

  if (n && len) {

    if ([self properselection] || [self insertionpoint]) {
      i = [startblock parindex];
      s = [[[paragraphs at:i] text] str];
      t = s + [startblock stringindex];
    } else {
      i = n - 1;
      s = [[[paragraphs at:i] text] str];
      t = s + strlen(s);
    }

    while (1) {
      if (t != s) {
	char *f = t;
	while (--f >= s) {
	  if (strncmp(f,fs,len)==0) {
	    return [self selectFrom:i:f-s to:i:f-s+len-1];
	  }
	}
      }
      if (--i >= 0) {
	s = [[[paragraphs at:i] text] str];
	t = s + strlen(s);
      } else {
	break;
      }
    }
  }

  XBell(maindisplay,100);
  return self;
}

- recomputeSelection
{
  if ([self insertionpoint]) {
    [self selectInvisiblyAt:[startblock parindex]:[startblock stringindex]]; 
  }
  if ([self properselection]) {
    [self selectInvisiblyFrom:[startblock parindex]:[startblock stringindex]
       to:[stopblock parindex]:[stopblock stringindex]];
    [richtext selrectsfrom:startblock to:stopblock];
  }
  return self;
}

- selectFrom:(int)pi:(int)ci to:(int)pj:(int)cj
{
  if ((startblock != nil && stopblock != nil) 
    && ([startblock parindex] == pi && [startblock stringindex] == ci)
    && ([stopblock parindex] == pj && [stopblock stringindex] == cj)) {
    return [self selectAndScroll];
  } else {
    [self deselect];
    [self selectInvisiblyFrom:pi:ci to:pj:cj];
    return [self selectAndScroll];
  }
}

- selectAll
{
  int n;
  id pgs = [richtext paragraphs];
  if ((n = [pgs size])) {
    int m = [[[pgs at:n-1] text] size];
    if (m) [self selectFrom:0:0 to:n-1:m-1];
    else [self selectFrom:0:0 to:n-1:0];
  }
  return self;
}

- makeRoman
{
  id x = [Fontchange new];
  id f = [richtext fontwithfamily:FFROMAN];
  [x setfontnum:[f fontnum]];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeSwiss
{
  id x = [Fontchange new];
  id f = [richtext fontwithfamily:FFSWISS];
  [x setfontnum:[f fontnum]];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeModern
{
  id x = [Fontchange new];
  id f = [richtext fontwithfamily:FFMODERN];
  [x setfontnum:[f fontnum]];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeFontsize:(int)points
{
  id x = [Fontsizechange new];
  [x setfontsize:points * 2]; /* RTF double points */
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makePlain
{
  id x = [Plain new];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeBold
{
  id x = [Boldface new];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeItalic
{
  id x = [Italic new];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- makeUnderlined
{
  id x = [Underlined new];
  [richtext addAttribute:x fromblock:startblock toblock:stopblock];
  [self setmodified:YES];
  return [self update];
}

- forkprint
{
  if (printcmd != nil && [printcmd size] > 1) {
     FILE *ps = popen([printcmd str],"w");
     if (ps) {
       [richtext writepostscript:ps];
       pclose(ps);
     } else {
       warndialog([self lastfocus],"Can't open pipe to %s.\n",[printcmd str]);
     }
  } else {
     warndialog([self lastfocus],"Can't open pipe for printing (no cmd).\n");
  }
  return self;
}

static void delayedprint(XtPointer clientdata,XtIntervalId *timer)
{
  [(id)clientdata forkprint];
}

- print
{
  if (printdialog(shell) == DLGOK) {
    XtAppAddTimeOut(maincontext,1,delayedprint,self);
  }
  return self;
}

@end

