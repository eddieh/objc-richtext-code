
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

#define ALGNLEFT   0
#define ALGNRIGHT  1
#define ALGNJUST   2
#define ALGNCENTER 3

@interface Style : Object
{
  int firstindent;
  int leftindent;
  int rightindent;
  int alignment;
  int spacebefore;
  int spaceafter;
  int spaceline;
  id tabs;
}

+ new;
- copy;
- free;

- pardefaults;

- tabs;
- tabs:x;
- settab:(int)num;
- (int)alignment;
- setalign:(int)num;

- (int)firstindent;
- setfirstindent:(int)num;
- (int)leftindent;
- setleftindent:(int)num;
- (int)rightindent;
- setrightindent:(int)num;

- (int)spacebefore;
- setspacebefore:(int)num;
- (int)spaceafter;
- setspaceafter:(int)num;
- (int)spaceline;
- setspaceline:(int)num;

- writertf:(IOD)d;

- (int)nextTabfromx:(int)x leftmargin:(int)lm rightmargin:(int)rm;

@end

