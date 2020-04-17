
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

#include <string.h>
#include <txtattr.h>
#include "fontsizechange.h"

@implementation Fontsizechange 

- (BOOL)istextattr
{
  return YES;
}

- (unsigned) hash
{
  return fontsize;
}

- (BOOL)dominates:b
{
  if ([b isKindOf:Fontsizechange]) return YES;
  if (![b istextattr]) return YES;
  return NO;
}

- (BOOL)isEqual:b
{
  return [b isKindOf:Fontsizechange] && [b fontsize] == fontsize;
}

- (int)fontsize
{
  return fontsize;
}

- setfontsize:(int)i
{
  fontsize = i;return self;
}

- writertf:(IOD)d
{
  fprintf(d,"\\fs%d",fontsize);
  return self;
}

@end

