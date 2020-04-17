
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

#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <Object.h>
#include <ocstring.h>
#include <rectangl.h>
#include <ordcltn.h>
#include <dictnary.h>
#include "AFM.h"
#include "lexafm.h"
#include "bbox.h"

@implementation AFM 

- syntaxerror
{
  lexafmtext[16] = '\0';
  return [self error:"syntax error at line %d (%s...) in '%s'",lexafmlineno,lexafmtext,[fname str]];
}

static BOOL getcharname(int tok)
{
  if (tok == kString) return YES;
  switch (tok) {
   case kB : lexafmlval.i = [String str:"B"];return YES; 
   case kC : lexafmlval.i = [String str:"C"];return YES; 
   case kL : lexafmlval.i = [String str:"L"];return YES; 
   case kN : lexafmlval.i = [String str:"N"];return YES; 
   case kW : lexafmlval.i = [String str:"W"];return YES; 
   default : break;
  }
  return NO;
}

static void done(id x)
{
  [x syntaxerror];
}

- parsefile
{
  int i,j,k,l,token;
  if (lexafmlex() != kStartFontMetrics) done(self);
  if (lexafmlex() != kDouble) done(self);
  while ((token=lexafmlex()) == kComment) {
    if (lexafmlex() != kString) done(self);
  }
  if (token != kFontName) done(self);
  if (lexafmlex() != kString) done(self); else FontName=lexafmlval.i;
  if (lexafmlex() != kFullName) done(self);
  if (lexafmlex() != kString) done(self); else FullName=lexafmlval.i;
  if (lexafmlex() != kFamilyName) done(self);
  if (lexafmlex() != kString) done(self); else FamilyName=lexafmlval.i;
  if (lexafmlex() != kWeight) done(self);
  if (lexafmlex() != kString) done(self); else Weight=lexafmlval.i;
  if (lexafmlex() != kItalicAngle) done(self);
  switch ((token = lexafmlex())) {
    case kLong: ItalicAngle = lexafmlval.l;break;
    case kDouble: ItalicAngle = lexafmlval.d;break;
    default: done(self);
  }
  if (lexafmlex() != kIsFixedPitch) done(self);
  if (lexafmlex() != kBool) done(self); else IsFixedPitch=lexafmlval.l;
  if (lexafmlex() != kFontBBox) done(self);
  if (lexafmlex() != kLong) done(self); else FontBBox_llx=lexafmlval.l;
  if (lexafmlex() != kLong) done(self); else FontBBox_lly=lexafmlval.l;
  if (lexafmlex() != kLong) done(self); else FontBBox_urx=lexafmlval.l;
  if (lexafmlex() != kLong) done(self); else FontBBox_ury=lexafmlval.l;
  if (lexafmlex() != kUnderlinePosition) done(self);
  if (lexafmlex() != kLong) done(self); else UnderlinePosition=lexafmlval.l;
  if (lexafmlex() != kUnderlineThickness) done(self);
  if (lexafmlex() != kLong) done(self); else UnderlineThickness=lexafmlval.l;
  if (lexafmlex() != kVersion) done(self);
  if (lexafmlex() != kString) done(self); else Version=lexafmlval.i;
  if (lexafmlex() != kNotice) done(self);
  if (lexafmlex() != kString) done(self); else Notice=lexafmlval.i;
  if (lexafmlex() != kEncodingScheme) done(self);
  if (lexafmlex() != kString) done(self); else EncodingScheme=lexafmlval.i;
  if (lexafmlex() != kCapHeight) done(self);
  if (lexafmlex() != kLong) done(self); else CapHeight=lexafmlval.l;
  if (lexafmlex() != kXHeight) done(self);
  if (lexafmlex() != kLong) done(self); else XHeight=lexafmlval.l;
  if (lexafmlex() != kAscender) done(self);
  if (lexafmlex() != kLong) done(self); else Ascender=lexafmlval.l;
  if (lexafmlex() != kDescender) done(self);
  if (lexafmlex() != kLong) done(self); else Descender=lexafmlval.l;
  if (lexafmlex() != kStartCharMetrics) done(self);
  if (lexafmlex() != kLong) done(self); else Characters=lexafmlval.l;
  CharacterSet = [OrdCltn new]; 
  for(token=lexafmlex();;) {
    int a,b,c,d;
    id bbox = [BoundingBox new];
    if (token != kC) done(self); else token = lexafmlex();
    if (token != kLong) done(self); else i=lexafmlval.l;
    [bbox setcharcode:i];
    token = lexafmlex();
    if (token != kSemi) done(self); else token = lexafmlex();
    if (token != kWX) done(self); else token = lexafmlex();
    if (token != kLong) done(self); else [bbox setwx:lexafmlval.l];
    token = lexafmlex();
    if (token != kSemi) done(self); else token = lexafmlex();
    if (token != kN) done(self); else token = lexafmlex();
    if (!getcharname(token)) done(self); else [bbox setcharname:lexafmlval.i];
    token = lexafmlex();
    if (token != kSemi) done(self); else token = lexafmlex();
    if (token != kB) done(self); else token = lexafmlex();
    if (token != kLong) done(self); else a = lexafmlval.l;token = lexafmlex();
    if (token != kLong) done(self); else b = lexafmlval.l;token = lexafmlex();
    if (token != kLong) done(self); else c = lexafmlval.l;token = lexafmlex();
    if (token != kLong) done(self); else d = lexafmlval.l;token = lexafmlex();
    if (token != kSemi) done(self); else token = lexafmlex();
    [bbox origin:a:b];
    [bbox corner:c:d];
    /* not interested in ligatures */
    while (token == kL) {
      token = lexafmlex();
      if (!getcharname(token)) done(self); else token = lexafmlex();
      if (!getcharname(token)) done(self); else token = lexafmlex();
      if (token != kSemi) done(self); else token = lexafmlex();
    }
    for(j=[CharacterSet size];j<i;j++) [CharacterSet add:[BoundingBox new]];
    [CharacterSet add:bbox];
    if (token == kEndCharMetrics) break;
  }
  
  /* we're not interested in kerning and ligatures (yet?) - stop parsing here */
  while (lexafmlex()) ;
  return self;
}

- syserror
{
  return [self error:strerror(errno)];
}

- open:(STR)filename
{
  id c;
  static id cache;
  if (!cache) cache = [Dictionary new];
  if ((c=[cache atKeySTR:filename])) return c;
  fname = [String str:filename];
  lexafmlineno = 1;
  if ( (lexafmin = fopen(filename,"r") ) ) {
   [self parsefile];
   if (fclose(lexafmin)) [self syserror];
  } else {
   [self syserror]; 
  }
  [cache atKey:fname put:self];
  return self;
}

+ open:(STR)filename
{
  return [[self new] open:filename];
}

- (long)Ascender
{
   return Ascender;
}

- (long)Descender
{
   return Descender;
}

- bboxes
{
   return CharacterSet;
}

- bboxAt:(int)c
{
   return [CharacterSet at:c];
}

- writepostscript:(IOD)psiod
{
   assert(FontName);
   fprintf(psiod,"/%s findfont",[FontName str]);
   return self;
}

@end

