
/*
 * Copyright (C) 1999 David Stes.
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
#include <assert.h>

#include <stdio.h>
#include <stdlib.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <X11/IntrinsicP.h>
#include <Xm/Xm.h>
#include <Xm/XmP.h>
#include <Xm/PrimitiveP.h>
#include "rtfwidget.h"
#include "rtfwidgetP.h"
#undef Object
#undef String

#include "richtext.h"
#include "document.h"
#include <octext.h>
#include <paragrph.h>
#include <runarray.h>
#include <ordcltn.h>
#include <rectangl.h>
#include "main.h"

#include "richfont.h"
#include "charscanner.h"
#include "compscanner.h"
#include "dispscanner.h"
#include "charblkscanner.h"

#define Object XtObject
/* XtWindow() and XtDisplay are casting to Object */
static Window getxwindow(void* w) { return XtWindow((Widget)w); }
static Display* getxdisplay(void* w) { return XtDisplay((Widget)w); }
#undef Object

int dblbuf = 1;

static GC getnormalgc(RtfWidget w)
{
  XGCValues values;
  values.function = GXcopy;
  values.background = w->core.background_pixel;
  values.foreground = w->core.screen->black_pixel;
  return XtGetGC((Widget)w,GCFunction|GCForeground|GCBackground,&values);
}

static GC getrevgc(RtfWidget w)
{
  XGCValues values;
  values.function = GXcopy;
  values.background = w->core.screen->black_pixel; 
  values.foreground = w->core.background_pixel;
  return XtGetGC((Widget)w,GCFunction|GCForeground|GCBackground,&values);
}

static GC gethilitegc(RtfWidget w)
{
  XGCValues values;
  values.function = GXxor;
  values.background = w->core.screen->black_pixel;
  values.foreground = values.background ^ w->core.background_pixel;
  return XtGetGC((Widget)w,GCFunction|GCForeground|GCBackground,&values);
}

static void trackvisibility(Widget w,XtPointer data,XEvent *event,Boolean *continueDispatch)
{
  RtfWidget me = (RtfWidget)data;
  XVisibilityEvent *ve = (XVisibilityEvent *)event; 
  me->richtext.allvisible = (ve->state == VisibilityUnobscured);
}

static void setscanners(RtfWidget w)
{
  id scanner;
  id rt = w->richtext.richtext;

  scanner = [DisplayScanner new];
  [scanner setwidget:(Widget)w];
  [scanner setxdisplay:getxdisplay(w)];
  [scanner setxwindow:(dblbuf)?w->richtext.buffer:getxwindow(w)];
  [scanner setrichtext:rt];
  [rt setdisplayscanner:scanner];

  scanner = [CompositionScanner new];
  [scanner setwidget:(Widget)w];
  [scanner setxdisplay:getxdisplay(w)];
  [scanner setxwindow:(dblbuf)?w->richtext.buffer:getxwindow(w)];
  [scanner setrichtext:rt];
  [rt setcompositionscanner:scanner];

  scanner = [CharacterBlockScanner new];
  [scanner setwidget:(Widget)w];
  [scanner setxdisplay:getxdisplay(w)];
  [scanner setxwindow:(dblbuf)?w->richtext.buffer:getxwindow(w)];
  [scanner setrichtext:rt];
  [rt setcharblockscanner:scanner];

  scanner = [DisplayScanner new];
  [[scanner setrichtext:rt] setpsrender];
  [rt setpsdisplayscanner:scanner];

  scanner = [CompositionScanner new];
  [[scanner setrichtext:rt] setpsrender];
  [rt setpscompositionscanner:scanner];
}

static void newbuffer(RtfWidget w,unsigned int width,unsigned int height)
{
  unsigned int depth;
  assert(w->core.screen != NULL);
  dbg("newbuffer %i %i\n",width,height);
  depth = w->core.screen->root_depth;
  w->richtext.buffer = XCreatePixmap(getxdisplay(w),getxwindow(w),width,height,depth);
}

void enablertfflush(RtfWidget w) { w->richtext.disableflush--; }
void disablertfflush(RtfWidget w) { w->richtext.disableflush++; }

static void flushbuffer(RtfWidget w,int left,int top,int width,int height) 
{
  GC gc;
  Drawable src,dst;
  Display *dp = getxdisplay(w);

  if (w->richtext.disableflush) return;

  dst = getxwindow(w);
  src = w->richtext.buffer;
  assert(dblbuf && src);
  gc = w->richtext.normalgc;

  dbg("flushbuffer %i %i %i %i\n",left,top,width,height);
  XCopyArea(dp,src,dst,gc,left,top,width,height,left,top);
}

static void flushwindow(RtfWidget w)
{
  flushbuffer(w,0,0,w->core.width,w->core.height);
}

static void freebuffer(RtfWidget w)
{
  if (w->richtext.buffer) XFreePixmap(getxdisplay(w),w->richtext.buffer);
  w->richtext.buffer=(Pixmap)0;
}

static void initialize(RtfWidget request, RtfWidget new)
{
  id rt = request->richtext.richtext;

  dbg("initialize\n");

  if (request->core.width == 0) {
    	new->core.width = twips2points((rt)?[rt paperw]:PAPERW);
  }
  if (request->core.height == 0) {
    	new->core.height = twips2points((rt)?[rt paperh]:PAPERH);
  }

  new->richtext.composedLines = NO;
  new->richtext.needComposeAll = NO;
  new->richtext.normalgc = getnormalgc(new);
  new->richtext.revgc = getrevgc(new);
  new->richtext.hilitegc = gethilitegc(new);

  if (dblbuf) {
    new->richtext.buffer = (Pixmap)0;
    new->richtext.allvisible = YES;
  } else {
    new->richtext.allvisible = YES;
    XtAddEventHandler((Widget)new, VisibilityChangeMask, False, trackvisibility,(XtPointer)new);
  }

  dbg("blinkrate %i\n",new->richtext.blinkrate);
}

static void destroy(RtfWidget w)
{
  dbg("destroy\n");
  XtReleaseGC((Widget)w,w->richtext.normalgc);
  XtReleaseGC((Widget)w,w->richtext.hilitegc);
  if (dblbuf) freebuffer(w);
  w->richtext.richtext = nil;
}

static void resize(RtfWidget w)
{
  id doc,rt;
  int ow,oh;
  doc = [Document fromwidget:(Widget)w];
  rt = [doc richtext];
  ow = twips2points([rt paperw]);
  oh = twips2points([rt paperh]);
  dbg("resize from (%d,%d) to (%d,%d)\n",ow,oh,w->core.width,w->core.height);
  [doc setmodified:(ow != w->core.width || oh != w->core.height)];
  [rt setpaperw:points2twips(w->core.width)];
  [rt setpaperh:points2twips(w->core.height)];

  if (w->richtext.buffer) {
     /* if we have an offscreen buffer it needs to be resized */
     freebuffer(w);
     newbuffer(w,w->core.width,w->core.height);
     setscanners(w); /* otherwise they hold a pointer to the old buf *
  }
  if (w->richtext.composedLines) {
    /* if we composed lines, then that info must now be recomputed */
    /* just set a flag, so that we leave resize() immediately */
    w->richtext.needComposeAll = YES;
    [doc updatescrollbar];
    /* generate expose events */
    if (!dblbuf) XClearArea(getxdisplay(w),getxwindow(w),0,0,w->core.width,w->core.height,YES);
  };
}

static void hilite(RtfWidget w,int left,int top,int width,int height) 
{
  int i,n;
  int x,y,xx,yy;
  id self = w->richtext.richtext;
  id rects = [self selrects];

  for(i=0,n=[rects size];i<n;i++) {
    id r = [rects at:i];
    x = [r left];
    y = [r top] - [self top];
    xx = [r right];
    yy = [r bottom] - [self top];
#if 0
    dbg("hilite ((%d,%d),(%d,%d)) clip ((%d,%d),(%d,%d))\n",
       x,y,xx,yy,left,top,left+width,top+height);
#endif
    if (x < left) x=left;
    if (y < top) y=top;
    if (xx > left+width) xx=left+width;
    if (yy > top+height) yy=top+height;
    if (xx>x && yy>y) {
       XFillRectangle(getxdisplay(w),(dblbuf)?w->richtext.buffer:getxwindow(w),w->richtext.hilitegc,x,y,xx-x,yy-y);
    }
  }

  XFlush(getxdisplay(w));
}

void reverseinsertpoint(RtfWidget w,id blk)
{
  id self;
  int x,y,h;
  
  self = w->richtext.richtext;
  x = [blk left];
  y = [blk top] - [self top];
  h = [blk height];

  XFillRectangle(getxdisplay(w),getxwindow(w),w->richtext.hilitegc,x,y,1,h);
  XFlush(getxdisplay(w));
}

void hiliteselrects(RtfWidget w)
{
  hilite(w,0,0,w->core.width,w->core.height);
  if (dblbuf) flushwindow(w);
}

static void drawself(RtfWidget w,int left,int top,int width,int height) 
{
  id self = w->richtext.richtext;
  BOOL havesel = ([[self selrects] size] != 0);

  /* in case we're hiliting, the bounding box has to be exact */
  /* this is only needed if (havesel) but needs to be reset anyway */
  [self setclip:left:top:width:height];

  dbg("drawself ((%d,%d),(%d,%d))\n",left,top,width,height);

  if (dblbuf) {
    XFillRectangle(getxdisplay(w),w->richtext.buffer,w->richtext.revgc,left,top,width,height);
  } else {
    XClearArea(getxdisplay(w),getxwindow(w),left,top,width,height,False);
  }

  if (w->richtext.composedLines == NO || w->richtext.needComposeAll) {
    /* case when we have no line info or when we have invalid line info */
    id doc = [Document fromwidget:(Widget)w];
    [doc setwaitcursor];
    if (w->richtext.needComposeAll) {
      [self composeAll];
      [doc recomputeSelection];
    }
    [self displayLines:top:height];
    [doc updatescrollbar];
    [doc setibeamcursor];
    w->richtext.composedLines = YES;
    w->richtext.needComposeAll = NO;
  } else {
    [self displayLines:top:height];
  }

  if (havesel) hilite(w,left,top,width,height);
}

void refreshwidget(RtfWidget w)
{
  if (dblbuf) {
    drawself(w,0,0,w->core.width,w->core.height);
    flushwindow(w);
  } else {
    XClearArea(getxdisplay(w),getxwindow(w),0,0,w->core.width,w->core.height,YES);
  }
}

void refreshparagraph(RtfWidget w,int parindex)
{
  int a,b;
  id rt = w->richtext.richtext;

  a = -[rt top] + [rt topAtLineIndex:parindex:0];
  b = [rt bottomOfLines:[[rt paralines] at:parindex]];

  if (a < 0) a=0;
  if (b > w->core.height) b=w->core.height;

  if (dblbuf) {
    drawself(w,0,a,w->core.width,b);
    flushbuffer(w,0,a,w->core.width,b);
  } else {
    XClearArea(getxdisplay(w),getxwindow(w),0,a,w->core.width,b,YES);
  }
}

void scrollwidget(RtfWidget w,int d)
{
  int width = w->core.width;
  int height = w->core.height;

  if (w->richtext.allvisible && ((0 < d && d < height) || (-height < d && d < 0))) {
    Display *dp;
    Window window;
    GC gc = w->richtext.normalgc;

    dp = getxdisplay(w);
    window = (dblbuf)?w->richtext.buffer:getxwindow(w);
    if (!window) return;

    dbg("copyarea %d\n",d);

    if (d > 0) {
      XCopyArea(dp,window,window,gc,0,d,width,height-d,0,0);
      drawself(w,0,height-d,width,d);
    } else {
      XCopyArea(dp,window,window,gc,0,0,width,height+d,0,-d);
      drawself(w,0,0,width,-d);
    }
    
    if (dblbuf) flushwindow(w);
  } else {
    /* this is to deal with situations where XCopyArea is doing weird */
    refreshwidget(w);
  }
}

static void redisplay(RtfWidget w, XExposeEvent *e, Region region)
{
  dbg("redisplay (%d,%d,%d,%d)\n",e->x,e->y,e->width,e->height);
  drawself(w,e->x,e->y,e->width,e->height);
  if (dblbuf) flushbuffer(w,e->x,e->y,e->width,e->height);
}

static Boolean setvalues(RtfWidget current,RtfWidget request,RtfWidget new)
{
  dbg("setvalues\n");
  return NO;
}

static void realize(RtfWidget w,XtValueMask *valueMask,XSetWindowAttributes *attributes)
{
  dbg("realize\n");

#if 0
  *valueMask |= CWBitGravity;
  attributes->bit_gravity = NorthWestGravity;
#endif

  (xmPrimitiveClassRec.core_class.realize)((Widget)w, valueMask, attributes);

  if (dblbuf) newbuffer(w,w->core.width,w->core.height);
  setscanners(w);
}

int getblinkrate(Widget w)
{
  RtfWidget rw = (RtfWidget)w; return rw->richtext.blinkrate;
}

char* getxlfdtemplate(Widget w,int ffamily,BOOL italic,BOOL bold)
{
  char *r;
  RtfWidget rw = (RtfWidget)w;

  switch (ffamily) {
    case FFDEFAULT :
    case FFROMAN : {
     if (italic) {
       r= (bold)?rw->richtext.romanbolditalic:rw->richtext.romanitalic;
     } else {
       r= (bold)?rw->richtext.romanbold:rw->richtext.romanplain;
     }
     break;
    }
    case FFSWISS : {
     if (italic) {
       r= (bold)?rw->richtext.swissbolditalic:rw->richtext.swissitalic;
     } else {
       r= (bold)?rw->richtext.swissbold:rw->richtext.swissplain;
     }
     break;
    }
    case FFMODERN : {
     if (italic) {
       r= (bold)?rw->richtext.modernbolditalic:rw->richtext.modernitalic;
     } else {
       r= (bold)?rw->richtext.modernbold:rw->richtext.modernplain;
     }
     break;
    }
    default : {
     break;
    }
  } 
 
  dbg("getxlfdtemplate %s\n",r);
  return r;
}

int getautoscroll(Widget w)
{
  RtfWidget rw = (RtfWidget)w; return rw->richtext.autoscroll;
}

char* getworddelimiters(Widget w)
{
  RtfWidget rw = (RtfWidget)w; return rw->richtext.delimiters;
}

static XtGeometryResult querygeometry(RtfWidget w, XtWidgetGeometry *proposed,XtWidgetGeometry *answer)
{
  dbg("querygeometry\n");
  return XtGeometryAlmost;
}

static void mousedownap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc mousedown:(XButtonEvent*)event];
}

static void shiftclickap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc shiftclick:(XButtonEvent*)event];
}

static void mousedragap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc mousemoved:(XButtonEvent*)event];
}

static void mouseupap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc mouseup:(XButtonEvent*)event];
}

static void keydownap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc keydown:event];
}

static void tabkeyap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc tabkey];
}

static void cursorlap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc cursorleft];
}

static void cursorrap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc cursorright];
}

static void cursoruap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc cursorup];
}

static void cursordap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc cursordown];
}

static void newlineap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc newline];
}

static void backspaceap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc backspace];
}

static void getfocusap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc select];
  [doc havefocus:YES];
}

static void loosefocusap(Widget w, XEvent *event, char **args, Cardinal *nargs)
{
  id doc = [Document fromwidget:w];
  [doc havefocus:NO];
  [doc deselect];
}

static char defaulttranslations[] = ""
  "<FocusIn>: getfocus()\n"
  "<FocusOut>: loosefocus()\n"
  "~Shift <Btn1Down>: mousedown()\n"
  "Shift <Btn1Down>: shiftclick()\n"
  "Button1 <Motion>: mousedrag()\n" /* don't use event sequence A&S p354 */
  "<Btn1Up>: mouseup()\n"
  "<Key>Return: newline()\n"
  "<Key>osfDelete: backspace()\n"
  "<Key>osfBackSpace: backspace()\n"
  "<Key>osfLeft: cursorleft()\n"
  "<Key>osfRight: cursorright()\n"
  "<Key>osfUp: cursorup()\n"
  "<Key>osfDown: cursordown()\n"
  "<Key>Tab: tabkey()\n"
  ":<Key>: keydown()\n"
;

static XtResource resources[] = {
  {rtfNrichtext,rtfCRichtext,XtRPointer,sizeof(id),
     XtOffsetOf(RtfwidgetRec,richtext.richtext),XtRImmediate,NULL},
  {rtfNscrollbar,rtfCScrollBar,XmRWidget,sizeof(Widget),
     XtOffsetOf(RtfwidgetRec,richtext.scrollbar),XmRString,""},
  {rtfNblinkrate,rtfCBlinkrate,XtRInt,sizeof(int),
     XtOffsetOf(RtfwidgetRec,richtext.blinkrate),XtRImmediate,0},
  {rtfNautoscroll,rtfCAutoscroll,XtRInt,sizeof(int),
     XtOffsetOf(RtfwidgetRec,richtext.autoscroll),XtRImmediate,0},
  {rtfNdelimiters, rtfCDelimiters, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.delimiters),XmRString,
    " \n\t.,/\\`'!@#%^&*()-=+{}[]\":;<>?"},
  {rtfNswissplain, rtfCSwissplain, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.swissplain),XmRString,
    "-*-helvetica-medium-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNswissitalic, rtfCSwissitalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.swissitalic),XmRString,
    "-*-helvetica-medium-o-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNswissbold, rtfCSwissbold, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.swissbold),XmRString,
    "-*-helvetica-bold-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNswissbolditalic, rtfCSwissbolditalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.swissbolditalic),XmRString,
    "-*-helvetica-bold-o-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNromanplain, rtfCRomanplain, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.romanplain),XmRString,
    "-*-times-medium-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNromanitalic, rtfCRomanitalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.romanitalic),XmRString,
    "-*-times-medium-i-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNromanbold, rtfCRomanbold, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.romanbold),XmRString,
    "-*-times-bold-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNromanbolditalic, rtfCRomanbolditalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.romanbolditalic),XmRString,
    "-*-times-bold-i-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNmodernplain, rtfCModernplain, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.modernplain),XmRString,
    "-*-courier-medium-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNmodernitalic, rtfCModernitalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.modernitalic),XmRString,
    "-*-courier-medium-o-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNmodernbold, rtfCModernbold, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.modernbold),XmRString,
    "-*-courier-bold-r-*-*-*-*-*-*-*-*-iso8859-1"},
  {rtfNmodernbolditalic, rtfCModernbolditalic, XmRString, sizeof(char*),
     XtOffsetOf(RtfwidgetRec,richtext.modernbolditalic),XmRString,
    "-*-courier-bold-o-*-*-*-*-*-*-*-*-iso8859-1"},
  {NULL, NULL, 0 , 0, 0, 0, NULL}
};

static XtActionsRec actionslist[] = {
  {"getfocus",getfocusap},
  {"loosefocus",loosefocusap},
  {"mousedown",mousedownap},
  {"shiftclick",shiftclickap},
  {"mousedrag",mousedragap},
  {"mouseup",mouseupap},
  {"keydown",keydownap},
  {"newline",newlineap},
  {"tabkey",tabkeyap},
  {"cursorleft",cursorlap},
  {"cursorright",cursorrap},
  {"cursorup",cursoruap},
  {"cursordown",cursordap},
  {"backspace",backspaceap},
  {"NULL",NULL}
};

RtfwidgetClassRec rtfwidgetClassRec = {
     /* CoreClassPart */
  {
    (WidgetClass) &xmPrimitiveClassRec,  /* superclass       */
    "Rtfwidget",                         /* class_name            */
    sizeof(RtfwidgetRec),                /* widget_size           */
    NULL,                           /* class_initialize      */
    NULL,                           /* class_part_initialize */
    FALSE,                          /* class_inited          */
    (XtInitProc)initialize,         /* initialize            */
    NULL,                           /* initialize_hook       */
    (XtRealizeProc)realize,         /* realize               */
    actionslist,                    /* actions               */
    XtNumber(actionslist),          /* num_actions           */
    resources,                      /* resources             */
    XtNumber(resources),            /* num_resources         */
    NULLQUARK,                      /* xrm_class             */
    TRUE,                           /* compress_motion       */
    XtExposeCompressMaximal|XtExposeGraphicsExposeMerged, /*compress_exposure*/
    TRUE,                           /* compress_enterleave   */
    FALSE,                          /* visible_interest      */
    (XtWidgetProc)destroy,          /* destroy               */
    (XtWidgetProc)resize,           /* resize                */
    (XtExposeProc)redisplay,        /* expose                */
    (XtSetValuesFunc)setvalues,     /* set_values            */
    NULL,                           /* set_values_hook       */
    XtInheritSetValuesAlmost,       /* set_values_almost     */
    NULL,                           /* get_values_hook       */
    NULL,                           /* accept_focus          */
    XtVersion,                      /* version               */
    NULL,                           /* callback private      */
    defaulttranslations,            /* tm_table              */
    (XtGeometryHandler)querygeometry, /* query_geometry        */
    NULL,                           /* display_accelerator   */
    NULL,                           /* extension             */
  },
  /* Motif primitive class fields */
  {
     (XtWidgetProc)_XtInherit,   	/* Primitive border_highlight   */
     (XtWidgetProc)_XtInherit,   	/* Primitive border_unhighlight */
     NULL, /*XtInheritTranslations,*/	/* translations                 */
     NULL,				/* arm_and_activate             */
     NULL,				/* get resources      		*/
     0,					/* num get_resources  		*/
     NULL,         			/* extension                    */
  },
  /* Rtfwidget class part */
  {
    0,                              	/* ignored	                */
  }
};

/* call this to force pulling in this objective-c module */

WidgetClass rtfWidgetClass;

void rtfwidgetinitialize(void)
{
  rtfWidgetClass = (WidgetClass)&rtfwidgetClassRec;
}

