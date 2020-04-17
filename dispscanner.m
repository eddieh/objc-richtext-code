
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

#include <assert.h>
#include <Object.h>
#include <octext.h>
#include <ordcltn.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#undef Object
#undef String

#include "charscanner.h"
#include "dispscanner.h"
#include "textline.h"
#include "richtext.h"
#include "style.h"

@implementation DisplayScanner 

- space
{
  destx += spacewidth;
  if (psrender && displaying) {
     [self putpschar:' '];
  }

  if ([textStyle alignment] == ALGNJUST) {
    int spc = [line spacecount];
    if (spc) destx += [line paddingwidth]/spc;
  }

  ++lastindex;
  stopscanning = NO;
  return self;
}

- setdestx
{
  switch([textStyle alignment]) {
    case ALGNLEFT  : destx = leftmargin;break;
    case ALGNRIGHT : destx = leftmargin + [line paddingwidth];break;
    case ALGNCENTER: destx = leftmargin + [line paddingwidth]/2;break;
    case ALGNJUST  : destx = leftmargin;break;
  }
  return self;
}

- tab
{
  destx = [textStyle nextTabfromx:destx leftmargin:leftmargin rightmargin:rightmargin]; 
  stopscanning = NO;
  ++lastindex;
  return self;
}

- newline
{
  stopscanning = NO;
  ++lastindex;
  return self;
}

- crossedx
{
  stopscanning = YES;
  return self;
}

- endOfRun /* we're one position after last run */
{
  int linebreak = [line last];
  if (lastindex > linebreak) {
    stopscanning = YES;
  } else {
    int length = [text runLengthFor:lastindex];
    runstopindex = lastindex + length - 1;
    if (runstopindex > linebreak) runstopindex = linebreak;
    [self setfont];
    stopscanning = NO;
  }
  if (displaying && needshow) [self endshow];
  return self;
}

- displayLine:aLine num:(int)i in:paragraph at:(int)liney
{
  int length,linebreak;

  assert(richtext != nil);
  [self setparagraph:paragraph];
  line = aLine;

  lastindex = [line first];
  linebreak = [line last];
  lineheight = [line lineheight];
  leftmargin = [richtext leftmarginIn:textStyle forLine:i];
  if (psrender) {
  rightmargin = [richtext psrightmarginIn:textStyle forLine:i]; 
  } else {
  rightmargin = [richtext rightmarginIn:textStyle forLine:i]; 
  }
  [self setdestx];
  desty = liney + [line ascent];
  length = [text runLengthFor:lastindex];
  runstopindex = lastindex + length - 1;
  if (runstopindex > linebreak) runstopindex = linebreak;

  displaying = YES;

  [self setfont]; /* also set by -endOfRun */

  for(stopscanning = NO;!stopscanning;) {
    [self scancharsfrom:lastindex to:runstopindex in:[text string] rightx:rightmargin];
  }

  return self;
}


@end

