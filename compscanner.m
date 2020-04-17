
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

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#undef Object
#undef String

#include "charscanner.h"
#include "compscanner.h"
#include "textline.h"
#include "richtext.h"
#include "style.h"

@implementation CompositionScanner 

- newline
{
  [line stop:lastindex];
  spacex = destx;
  [line paddingwidth:rightmargin - destx]; /* could be used for center */
  stopscanning = YES;
  return self;
}

- space
{
  spacex = destx;
  ascentatspace = ascent; /* to be able to restore them later */
  descentatspace = descent;
  spaceindex = lastindex;
  spacecount++; /* record them for linebreaking/justif. purposes */
  destx += spacewidth;
  ++lastindex;
  stopscanning = NO;
  if (destx > rightmargin) return [self crossedx];
  return self;
}

- tab
{
  int newx;
  newx = [textStyle nextTabfromx:destx leftmargin:leftmargin rightmargin:rightmargin]; 
  /* Squeak is doing a crossedx here, but I find newline more logical */
  if (newx >= rightmargin) return [self newline]; 
  destx= newx;
  ++lastindex;
  stopscanning = NO;
  return self;
}

- crossedx
{
  int linebegin = [line first];
  if (spacecount) {
    [line stop:spaceindex];

    /* for purposes of justification, set spacecount and paddingwidth
     * to first space at end (if there were multiple spaces at end of line)
     */

    --spacecount;
    --spaceindex;
    while (spaceindex > linebegin && [text charAt:spaceindex] == ' ') {
      --spacecount;
      --spaceindex;
      spacex -= spacewidth;
    }

    [line spacecount:spacecount];
    [line paddingwidth:rightmargin - spacex];

    ascent = ascentatspace;
    descent = descentatspace;
    spacecount = 0;
    stopscanning = YES;
    return self;
  } else {
    --lastindex; 
    spacex = destx;
    [line spacecount:spacecount];
    [line paddingwidth:rightmargin - destx];
    [line stop:(lastindex>linebegin)?lastindex:linebegin];
    stopscanning = YES;
    return self;
  }
}

- endOfRun /* one position after last run now */
{
  if (lastindex == [text size]) {
    [line stop:lastindex - 1];
    spacex = destx;
    [line paddingwidth:rightmargin - destx];
    stopscanning = YES;
    return self;
  } else {
    int length = [text runLengthFor:lastindex];
    runstopindex = lastindex + length - 1;
    [self setfont]; /* start of new run -- reset font for run */
    stopscanning = NO;
    return self;
  }
}

- composeLine:(int)i from:(int)from in:paragraph
{
  [self setparagraph:paragraph];

  ascent = 0;
  descent = 0;
  spacecount = 0;

  leftmargin = [richtext leftmarginIn:textStyle forLine:i];
  destx = leftmargin;
  desty = 0;
  spacex = leftmargin; 
  spacecount = 0;
  if (psrender) {
  rightmargin = [richtext psrightmarginIn:textStyle forLine:i];
  } else {
  rightmargin = [richtext rightmarginIn:textStyle forLine:i];
  }
  if (leftmargin >= rightmargin) {
    dbg("Leftmargin overflow. No room between margins\n");
    while (leftmargin >= rightmargin) leftmargin -= rightmargin;
  }

  lastindex = from;
  runstopindex = from + [text runLengthFor:from] - 1;

  line = [TextLine new];
  [line start:lastindex];

  stopscanning = NO;
  displaying = NO;

  [self setfont]; /* also set by -endOfRun */

  while (!stopscanning) {
    id str = [text string];
    [self scancharsfrom:lastindex to:runstopindex in:str rightx:rightmargin];
  }

  [line ascent:ascent descent:descent];
  return line;
}

- (int)rightx
{
  return spacex;
}

@end

