
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
#include "plain.h"
#include "boldface.h"
#include "italic.h"
#include "underlined.h"

@implementation Plain 

static id me;

- (BOOL)istextattr
{
  return YES;
}

+ new
{
  if (!me) me = [super new];
  return me;
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

- (BOOL)dominates:b
{
  if ([b isKindOf:Italic]) return YES;
  if ([b isKindOf:Boldface]) return YES;
  if ([b isKindOf:Underlined]) return YES;
  if (![b istextattr]) return YES;
  return NO;
}

- (BOOL)set
{
  /* the role of Plain is just to dominate other styles, */
  /* it doesn't actually have to be added -- it isn't "set" */
  return NO;
}

- (BOOL)isEqual:b
{
  return b == me;
}

@end

