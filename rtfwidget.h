
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

#define rtfNrichtext "richtext"
#define rtfCRichtext "Richtext"
#define rtfNscrollbar "scrollbar"
#define rtfCScrollBar "ScrollBar"
#define rtfNblinkrate "blinkrate"
#define rtfCBlinkrate "Blinkrate"
#define rtfNautoscroll "autoscroll"
#define rtfCAutoscroll "Autoscroll"
#define rtfNdelimiters "delimiters"
#define rtfCDelimiters "Delimiters"
#define rtfNswissplain "swissplain"
#define rtfCSwissplain "Swissplain"
#define rtfNswissbold "swissbold"
#define rtfCSwissbold "Swissbold"
#define rtfNswissitalic "swissitalic"
#define rtfCSwissitalic "Swissitalic"
#define rtfNswissbolditalic "swissbolditalic"
#define rtfCSwissbolditalic "Swissbolditalic"
#define rtfNromanplain "romanplain"
#define rtfCRomanplain "Romanplain"
#define rtfNromanbold "romanbold"
#define rtfCRomanbold "Romanbold"
#define rtfNromanitalic "romanitalic"
#define rtfCRomanitalic "Romanitalic"
#define rtfNromanbolditalic "romanbolditalic"
#define rtfCRomanbolditalic "Romanbolditalic"
#define rtfNmodernplain "modernplain"
#define rtfCModernplain "Modernplain"
#define rtfNmodernbold "modernbold"
#define rtfCModernbold "Modernbold"
#define rtfNmodernitalic "modernitalic"
#define rtfCModernitalic "Modernitalic"
#define rtfNmodernbolditalic "modernbolditalic"
#define rtfCModernbolditalic "Modernbolditalic"

extern WidgetClass rtfWidgetClass;

typedef struct _RtfwidgetClassRec *RtfWidgetClass;
typedef struct _RtfwidgetRec *RtfWidget;

void rtfwidgetinitialize(void);
void enablertfflush(RtfWidget w);
void disablertfflush(RtfWidget w);
void refreshwidget(RtfWidget w);
void refreshparagraph(RtfWidget w,int i);
void scrollwidget(RtfWidget w,int d);
void hiliteselrects(RtfWidget w);
void reverseinsertpoint(RtfWidget w,id blk);
int  getblinkrate(Widget w);
int  getautoscroll(Widget w);
char* getworddelimiters(Widget w);
char* getxlfdtemplate(Widget w,int ffamily,BOOL italic,BOOL bold);

