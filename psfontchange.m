
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
#include <rectangl.h>
#include <txtattr.h>
#include <ordcltn.h>
#include <set.h>
#include <assert.h>

#include "psfontchange.h"
#include "richfont.h"
#include "fontchange.h"
#include "boldface.h"
#include "italic.h"
#include "fontsizechange.h"
#include "richtext.h"
#include "AFM.h"
#include "bbox.h"

@implementation PSFontchange 

- (BOOL)istextattr
{
  return NO;
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

- (unsigned) hash
{
  unsigned h = (italic)?0:1;
  h = (h << 1) | (boldface)?0:1;
  h = (h << 8) | (fontsize % 255);
  h = (h << 8) | (fontfamily % 255);
  return h;
}

- afm
{
  if (afm) {
     return afm;
  } else {
     char *fn;
     switch (fontfamily) {
       case FFDEFAULT :
       case FFROMAN :
         if (italic) {
            fn = (boldface)?"afm/romanbolditalic.afm":"afm/romanitalic.afm";
         } else {
            fn = (boldface)?"afm/romanbold.afm":"afm/romanplain.afm";
         }
       break;
       case FFSWISS :
         if (italic) {
            fn = (boldface)?"afm/swissbolditalic.afm":"afm/swissitalic.afm";
         } else {
            fn = (boldface)?"afm/swissbold.afm":"afm/swissplain.afm";
         }
       break;
       case FFMODERN :
         if (italic) {
            fn = (boldface)?"afm/modernbolditalic.afm":"afm/modernitalic.afm";
         } else {
            fn = (boldface)?"afm/modernbold.afm":"afm/modernplain.afm";
         }
       break;
       default : [self error:"unknown font family"];
     }
     /* the AFM call also a small cache */
     afm = [AFM open:findafmfile(fn)];
     return afm;
  }
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
  if ([x isKindOf:PSFontchange]) {

   return italic == [x italic] && boldface == [x boldface] && fontfamily == [x fontfamily] && fontsize == [x fontsize];
  } else {

   /* implement this as YES so that RunArray -coalesce works */
   /* it should ignore psfontchange stuff (wrt. other types of Fontattr) */

   return YES;
  }
}

- calcpsfontfor:ats in:text
{
  id f,g;
  int i,n;
  id afmset;
  int fontnum; /* for psfontchange it's the fontfamily that really matters */

  /* RTF specifies size in 2x */
  fontsize = FONTSIZE / 2;
  fontnum = [text defaultfont];
  italic = NO;
  boldface = NO;

  afmset = [text afmset]; /* cache on a per doc basis */

  for(i=0,n=[ats size];i<n;i++) {
    id a = [ats at:i];
    if ([a isKindOf:Italic]) {italic = YES;continue;}
    if ([a isKindOf:Boldface]) {boldface = YES;continue;}
    if ([a isKindOf:Fontchange]) {fontnum = [a fontnum];continue;}
    if ([a isKindOf:Fontsizechange]) {fontsize = ([a fontsize]/2);continue;}
  }

  f=[text fontwithnum:fontnum];
  assert(f);
  fontfamily = [f fontfamily];

  /* hash based on fontfamily, bold, italic, fontsize */
  if ((g=[afmset find:self])) {
    return g;
  } else {
    [afmset add:self];
    /* the AFM call also a small cache */
    [self afm];
    return self;
  }
}

- setfontchange:x
{
  return [self shouldNotImplement:_cmd];
}

- emphasizeScanner:aScanner
{
  [aScanner setfontchange:self];
  return self;
}

- (int)ascent
{
  return (fontsize * [afm Ascender] + 500) / 1000;
}

- (int)descent
{
  return (fontsize * (-[afm Descender]) + 500) / 1000;
}

- (int)widthOfChar:(char)x
{
  id b = [afm bboxes];
  if (0 <= x && x < [b size]) { 
    return (fontsize * [[b at:x] wx] + 500) / 1000;
  } else {
    fprintf(stderr,"warning character %u (%c) no bbox found\n",(unsigned)x,x);
    return 0;
  }
}

- writepostscript:(IOD)psiod
{
  [afm writepostscript:psiod];
  fprintf(psiod," [%d 0 0 -%d 0 0] makefont setfont\n",fontsize,fontsize);
  return self;
}

@end

