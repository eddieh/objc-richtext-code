
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

#define DTEXT    0
#define DIGNORE  1
#define DFNTABLE 2

@interface State : Object
{
  id richtext;
  int destination;
  BOOL boldface;
  BOOL italic;
  BOOL underlined;
  int fontnum;
  int fontfamily;
  int fontsize;
}

- richtext;
- richtext:t;
- textStyle;

- pardefaults;
- chardefaults;
- newparagraph;

- setboldface:(BOOL)flag;
- setitalic:(BOOL)flag;
- setunderlined:(BOOL)flag;
- setfontnum:(int)num;
- setfontsize:(int)num;
- setfontfamily:(int)fam;

- setforecolor:(int)num;
- setbackcolor:(int)num;

- setdestination:(int)d;

- add:s;
- addch:(char)c;
- addchars:(char*)s;
- addchars:(char*)s count:(int)n;

@end

