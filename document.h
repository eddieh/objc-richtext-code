
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

@interface Document : Object
{
  id path;
  id filename;
  Widget mainw;
  Widget shell;
  Widget scrollbar;
  Widget scrolledwindow;
  Widget textwidget;
  Widget lastfocus;
  Widget menubar;
  Widget windowsmenu;
  BOOL modified;
  BOOL readonly;
  BOOL untitled;
  BOOL havefocus;
  BOOL selectionshowing;
  id richtext;
  id startblock;
  id stopblock;
  id pivotblock;
  id begintypeblock;
  XtIntervalId blinktimer;
  XtIntervalId autoscrolltimer;
  int mousex,mousey;
}

+ initialize;

+ new;
+ open:(char*)fn;
+ fromwidget:(Widget)w;
+ closeall;
+ documents;
+ rearrange;
- save;
- saveas;
- revert;
- open;
- close;
- free;

- richtext;
- richtext:rt;

- xtownsel;
- xtdisownsel;

- cutclipboard;
- copyclipboard;
- pasteclipboard;
- delete;
- zapSelection:(char*)s count:(int)n;

- setwaitcursor;
- setibeamcursor;

- setuntitledname;
- setfilename:(char*)fn;
- setwindowtitle:(char*)fn;
- (char*)filename;
- (char*)path;

- (Widget)lastfocus;
- (Widget)menubar;
- (Widget)shell;

- update;
- updatewindowsmenu;
- scroll:(int)y;
- updatescrollbar;
- (Widget)windowsmenu;
- setwindowsmenu:(Widget)w;

- (BOOL)modified;
- setmodified:(BOOL)flag;
- (BOOL)readonly;
- setreadonly:(BOOL)flag;
- (BOOL)isuntitled;
- setuntitled:(BOOL)flag;
- (BOOL)havefocus;
- havefocus:(BOOL)flag;

- find;
- enterselection;
- findnext;
- findprevious;

- stopblock;
- startblock;
- (BOOL)insertionpoint;
- (BOOL)properselection;
- extendSelection:blk;
- extendWordSelection:blk;
- extendLineSelection:blk;
- recomputeSelection;
- reverseSelection;
- select;
- selectAt:blk;
- selectWordAt:blk;
- selectLineAt:blk;
- deselect;
- selectAndScroll;
- selectAll;
- selectFrom:(int)pi:(int)ci to:(int)pj:(int)cj;
- selectInvisiblyAt:(int)pi:(int)ci;
- selectInvisiblyFrom:(int)pi:(int)ci to:(int)pj:(int)cj;
- raise;

- makeRoman;
- makeSwiss;
- makeModern;

- makePlain;
- makeBold;
- makeItalic;
- makeUnderlined;

- makeFontsize:(int)points;

- blink;
- stopBlink;
- startBlink;

- autoscroll;
- stopAutoscroll;
- startAutoscroll;

- newline;
- backspace;
- tabkey;
- cursorleft;
- cursorright;
- cursorup;
- cursordown;
- keydown:(XEvent*)event;
- mousedown:(XButtonEvent*)event;
- shiftclick:(XButtonEvent*)event;
- mousemoved:(XButtonEvent*)event;
- mouseup:(XButtonEvent*)event;

- print;

@end

