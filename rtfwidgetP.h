
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

typedef struct _RtfwidgetClassPart{
  int ignore;
} RtfwidgetClassPart;

typedef struct _RtfwidgetClassRec {
  CoreClassPart  coreclass;
  XmPrimitiveClassPart primitiveclass;
  RtfwidgetClassPart  rtfclass;
} RtfwidgetClassRec;

extern RtfwidgetClassRec rtfwidgetClassRec;

typedef struct _RtfwidgetPart {

  /* resource instance variables */

  id richtext;
  Widget scrollbar;
  int blinkrate;
  int autoscroll;
  char *delimiters;
  char *swissplain;
  char *swissbold;
  char *swissitalic;
  char *swissbolditalic;
  char *romanplain;
  char *romanbold;
  char *romanitalic;
  char *romanbolditalic;
  char *modernplain;
  char *modernbold;
  char *modernitalic;
  char *modernbolditalic;

  /* private instance variables */

  GC revgc;
  GC normalgc;
  GC hilitegc;
  Pixmap buffer;
  BOOL composedLines;
  BOOL needComposeAll;
  BOOL allvisible; /* to work around XCopyArea problem for obscured windows */
  int disableflush; /* in double buffered case */

} RtfwidgetPart;

typedef struct _RtfwidgetRec {
   CorePart        core;
   XmPrimitivePart primitive;
   RtfwidgetPart   richtext;
} RtfwidgetRec;

