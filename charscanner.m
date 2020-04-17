
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

#include <assert.h>
#include <Object.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <X11/IntrinsicP.h>
#undef Object
#undef String

#include <ordcltn.h>
#include <octext.h>
#include <paragrph.h>
#include <txtattr.h>
#include "xfontchange.h"
#include "psfontchange.h"
#include "textline.h"
#include "richtext.h"
#include "charscanner.h"
#include "style.h"
#include "AFM.h"

@implementation CharacterScanner 

- setwidget:(Widget)w
{
  widget = w;
  return self;
}

- setpsiod:(IOD)d
{
  psiod = d;
  return self;
}

- startpage:(int)n:(int)px:(int)py
{
  oldfontchange = nil;/* force it to be reset */
  fprintf(psiod,"%%%%Page: (%d) %d\n",n,n);
  fprintf(psiod,"/saveobj save def\n");
  fprintf(psiod,"%d %d translate\n",PSMARGIN,py - PSMARGIN);
  fprintf(psiod,"1 -1 scale\n");
  return self;
}

- showpage
{
  fprintf(psiod,"showpage\n");
  fprintf(psiod,"saveobj restore\n");
  return self;
}

- putpschar:(int)c
{
  if (!needshow) [self startshow];
  switch (c) {
    case '(' :
    case ')' : putc('\\',psiod);putc(c,psiod); break;
    default  : putc(c,psiod);break;
  }
}

- setxwindow:(Drawable)w
{
  xwin = w;
  return self;
}

- setxdisplay:(Display*)w
{
  xdpy = w;
  return self;
}

- makegc
{
  XGCValues values;
  values.function = GXcopy;
  gc = XCreateGC(xdpy,xwin,GCFunction,&values);
  return self;
}

- setpsrender
{
  psrender++;
  return self;
}

- startshow
{
   if (oldfontchange != fontchange) [fontchange writepostscript:psiod];
   needshow++;
   oldfontchange = fontchange;
   fprintf(psiod,"%d %d moveto\n",destx,desty);
   fprintf(psiod,"(");
   return self;
}

- endshow
{
  if (needshow) fprintf(psiod,") show\n");
  needshow = 0;
  return self;
}

- setgc
{
  XGCValues values;
  if (!gc) [self makegc]; 
  values.font = font->fid;
  XChangeGC(xdpy,gc,GCFont,&values);
  return self;
}

- setclip:(int)left:(int)top:(int)width:(int)height
{
  XRectangle rect;

  rect.x = left;
  rect.y = top;
  rect.width = width;
  rect.height = height;

  if (!gc) [self makegc]; 
  XSetClipRectangles(xdpy,gc,0,0,&rect,1,Unsorted);
  return self;
}

- free
{
  if (gc) { XFreeGC(xdpy,gc);gc = NULL; }
  return self;
}

- setfontchange:x
{
  fontchange = x;return self;
}

- setxfont:(XFontStruct *)f
{
  font = f; return self;
}

- addpsfont:attrs
{
  id psfc = [PSFontchange new];
  psfc = [psfc calcpsfontfor:attrs in:richtext];
  [attrs add:psfc];
  [psfc emphasizeScanner:self];
  return self;
}

- addxfont:attrs
{
  id xfc = [XFontchange new];
  [xfc setxdisplay:xdpy];
  [xfc setwidget:widget];
  xfc = [xfc calcxfontfor:attrs in:richtext];
  [attrs add:xfc];
  [xfc emphasizeScanner:self];
  return self;
}

- setfont
{
  id attrs;

  fontchange = nil;
  font = NULL;

  attrs = [text attributesAt:lastindex];
  [attrs elementsPerform:@selector(emphasizeScanner:) with:self];


  if (psrender) {
    if (!fontchange) [self addpsfont:attrs];
    if (ascent < [fontchange ascent]) ascent = [fontchange ascent];
    if (descent < [fontchange descent]) descent = [fontchange descent];
    spacewidth = [fontchange widthOfChar:' '];
    lineheight = ascent + descent;
    lastcharascent = [fontchange ascent];
    lastcharh = [fontchange ascent] + [fontchange descent];
    if (displaying && needshow) [self endshow];
  } else {
    if (!font) [self addxfont:attrs];
    if (ascent < font->ascent) ascent = font->ascent;
    if (descent < font->descent) descent = font->descent;
    spacewidth = XTextWidth(font," ",1);
    lineheight = ascent + descent;
    lastcharascent = font->ascent;
    lastcharh = font->ascent + font->descent;
    if (displaying) { [self setgc]; }
  } 

  return self;
}

- setparagraph:paragraph
{
  text = [paragraph text];
  textStyle = [paragraph textStyle];
  return self;
}

- setrichtext:rt
{
  richtext = rt;
  return self;
}

- space
{
  return [self subclassResponsibility];
}

- tab
{
  return [self subclassResponsibility];
}

- newline
{
  return [self subclassResponsibility];
}

- crossedx
{
  return [self subclassResponsibility];
}

- endOfRun
{
  return [self subclassResponsibility];
}

- scancharsfrom:(int)p to:(int)q in:string rightx:(int)rightx 
{
  char *ptr = [string str];

  lastindex = p;
  while (stopscanning == NO && lastindex <= q) {
    char c = ptr[lastindex];

    switch (c) {
      case ' '  : {
	[self space];
	break;
      }
      case '\n' : {
	[self newline];
	break;
      }
      case '\t' : {
	[self tab];
	break;
      }
      default   : {
	int newx;
        if (psrender) {
          newx = destx + (lastcharw = [fontchange widthOfChar:c]);
          if (displaying) [self putpschar:c];
        } else {
          newx = destx + (lastcharw = XTextWidth(font,&c,1));
	  if (displaying) XDrawString(xdpy,xwin,gc,destx,desty,&c,1);
        }
	if (newx > rightx) {
	  return [self crossedx];
	} else {
	  destx = newx;
	}
        ++lastindex;
	break;
      }
    }
  }

  return (stopscanning)?self:[self endOfRun];
}

@end

