
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

@interface CharacterScanner : Object
{
  id text;
  id richtext;
  id textStyle;
  int leftmargin;
  int rightmargin;
  int lastindex;
  int runstopindex;
  int spacewidth;
  int spaceindex;
  int spacecount;
  int destx,desty;
  int lineheight;
  int ascent;
  int descent;
  int lastcharw;
  int lastcharh;
  int lastcharascent;
  id line;
  BOOL displaying;
  BOOL stopscanning;
  BOOL psrender;
  BOOL needshow;
  GC gc;
  IOD psiod;
  id fontchange; /* rendering postscript - TODO: use also with xfontchange */
  id oldfontchange; /* prevent resetting font if it was same */ 
  Widget widget;
  Drawable xwin; /* either xwin of widget or a Pixmap */
  Display *xdpy;
  XFontStruct *font;
}

/* X window stuff */

- setwidget:(Widget)w;
- setxwindow:(Drawable)w;
- setxdisplay:(Display*)w;
- setxfont:(XFontStruct *)f;
- setgc;
- setfont;

/* PS stuff */

- setfontchange:a;
- setpsiod:(IOD)x;
- putpschar:(int)c;
- setpsrender;
- startshow;
- endshow;

- setrichtext:rt;
- setparagraph:paragraph;

/* scanning */

- scancharsfrom:(int)from to:(int)to in:text rightx:(int)rightx;

/* subclass responsibility */

- tab;
- space;
- newline;
- crossedx;
- endOfRun;

@end

