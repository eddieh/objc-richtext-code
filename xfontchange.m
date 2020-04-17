
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

#include <Object.h>
#include <txtattr.h>
#include <ordcltn.h>
#include <set.h>
#include <assert.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#undef Object
#undef String

#include "rtfwidget.h"

#include "xfontchange.h"
#include "richfont.h"
#include "fontchange.h"
#include "boldface.h"
#include "italic.h"
#include "fontsizechange.h"
#include "richtext.h"
#include "charscanner.h"

@implementation XFontchange 

- (BOOL)istextattr
{
  return NO;
}

- setwidget:(Widget)w
{
  widget = w; /* need this, because font prefs are set on a per widget basis */
  return self;
}

- setxdisplay:(Display*)d
{
  xdpy = d;
  return self;
}

- copy
{
  return self;
}

- deepCopy
{
  return self;
}

- free
{
  return nil;
}

- setxfont:(XFontStruct *)f
{
  font = f;
  return self;
}

int validxlfd(char *s)
{
 if (s) {
  int c,hyphens = 0;
  while ((c = *s++)) if (c == '-') hyphens++;
  return hyphens == 14;
 } else {
  return 0;
 }
}

int scalablexlfd(char *name)
{
 if (validxlfd(name)) {
  int i,field;
  for(i=0,field=0;name[i] != '\0';i++) {
   if (name[i] == '-') {
    field++;
    if ((field==7)||(field==8)||(field==12)) {
     if ((name[i+1] != '0') || (name[i+2] != '-')) {
      return 0;
     }
    }
   }
  }
  return 1;
 } else {
  return 0;
 }
}

int scalablexlfdinlist(char **s,int n)
{
  while (n--) if (scalablexlfd(*s++)) return 1;
  return 0;
}

int getxlfdfieldat(char *s,int nfield)
{
  int i,field;
  int value = 0;

  assert(field < 14);

  for(i=0,field=0;field <= nfield && s[i] != '\0';i++) {
    if (s[i] == '-') {
      field++;
    } else {
      if (field == nfield) {
        if ('0' <= s[i] && s[i] <= '9') value = value * 10 + (s[i] - '0'); 
      }
    }
  }
 
  return value;
}

int getsizeofxlfd(char *s)
{
  return getxlfdfieldat(s,7 /* point size */);
}

static int findmatch(char **fontlist,int n,int fs)
{
   int i;
   int min;
   int match = fs;
   for(i=0;i<n;i++) {
     int d,s = getsizeofxlfd(fontlist[i]);
     d = (s > fs)?(s-fs):(fs-s);
     if (d==0) return fs;
     if (i==0 || d<min) {min=d;match=s;}
   }
   return match;
}

XFontStruct *LoadQueryScalablefont(Display *dpy,char *s,int n)
{
  char t[512];
  int i,j,field;

  if (strlen(s)+16 >= 512 || n == 0 || !validxlfd(s)) return NULL;

  for(i=0,j=0,field=0;s[i]!='\0';i++) {
    t[j++] = s[i];
    if (s[i] == '-') {
      field++;
      if (field == 7 /* point size */ && s[i+1] == '*') {
        i++;
        sprintf(&t[j],"%d",n);
        while (t[j] != '\0') j++;
      }
    }
  }
 
  t[j++] = '\0';
  assert(field == 14);
  dbg("xloadquery %s\n",t);
  return XLoadQueryFont(dpy,t);
}

- (unsigned) hash
{
  unsigned h = (italic)?0:1;
  h = (h << 1) | (boldface)?0:1;
  h = (h << 8) | (fontsize % 255);
  h = (h << 8) | (fontfamily % 255);
  return h;
}

- (BOOL)italic
{
  return italic;
}

- (BOOL)boldface
{
   return boldface;
}

- (int)fontfamily
{
  return fontfamily;
}

- (int)fontsize
{
  return fontsize;
}

- (BOOL)isEqual:x
{
  if (self == x) return YES;
  if ([x isKindOf:XFontchange]) {

   /* this is used for xfontset hash/isEqual */

   return italic == [x italic] && boldface == [x boldface] && 
     fontsize == [x fontsize] && fontfamily == [x fontfamily];
  } else {

   /* implement this as YES so that RunArray -coalesce works */
   /* it should ignore xfontchange stuff (wrt. other types of Fontattr) */

   return YES;
  }
}

- calcxfontfor:ats in:text
{
  id f,g;
  int i,n;
  id fontset;
  int fontnum; /* for xfontchange it's the fontfamily that really matters */

  fontsize = FONTSIZE;
  fontnum = [text defaultfont];
  italic = NO;
  boldface = NO;

  fontset = [text xfontset]; /* cache on a per doc basis */

  for(i=0,n=[ats size];i<n;i++) {
    id a = [ats at:i];
    if ([a isKindOf:Italic]) {italic = YES;continue;}
    if ([a isKindOf:Boldface]) {boldface = YES;continue;}
    if ([a isKindOf:Fontchange]) {fontnum = [a fontnum];continue;}
    if ([a isKindOf:Fontsizechange]) {fontsize = [a fontsize];continue;}
  }

  f=[text fontwithnum:fontnum];
  assert(f);
  fontfamily = [f fontfamily];

  /* hash based on fontfamily, fontsize, bold, italic */
  if ((g=[fontset find:self])) {
    return g;
  } else {
    char *fname;
    [fontset add:self];
    fname = getxlfdtemplate(widget,fontfamily,italic,boldface); 
    if (!validxlfd(fname)) {
      [self error:"%s is not a well formed XLFD (must have 14 fields)."];
    } else {
      BOOL canscale;
      char **fontlist;
      int xsize = fontsize / 2; /* rtf specifies fontsize in 2 x points */
      fontlist = XListFonts(xdpy,fname,50,&n);
      if (n == 0) [self error:"Can't find %s fonts.",fname];
      canscale = scalablexlfdinlist(fontlist,n);
      if (!canscale) {
        dbg("looking for %s at %d points.\n",fname,xsize);
        xsize = findmatch(fontlist,n,xsize); /* modify size a bit */
      } else {
        dbg("looking for %s at %d points (scalable).\n",fname,xsize);
      }
      [self setxfont:LoadQueryScalablefont(xdpy,fname,xsize)];
      if (!font) [self error:"Can't load %s at %d points.\n",fname,xsize];
      XFreeFontNames(fontlist);
      return self;
    }
  }
}

- emphasizeScanner:aScanner
{
  [aScanner setxfont:font];
  return self;
}

@end

