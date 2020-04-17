
/*
 * Copyright (C) 1999 David Stes.
 *
 * This program is free software you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published 
 * by the Free Software Foundation either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

union lexafm {
  id i;
  long l;
  double d;
};

extern FILE* lexafmin;
extern int lexafmlineno;
extern char* lexafmtext;
extern union lexafm lexafmlval; 
extern int lexafmlex();

#define kString 1
#define kLong 2
#define kDouble 3
#define kBool 4

#define kSemi 10 

#define kAscender 21
#define kAxes 22
#define kAxisLabel 23
#define kAxisType 24
#define kB 25
#define kBlendAxisTypes 26
#define kBlendDesignMap 27
#define kBlendDesignPositions 28
#define kC 29
#define kCC 30
#define kCH 31
#define kCapHeight 32
#define kCharWidth 33
#define kCharacterSet 34
#define kCharacters 35
#define kComment 36
#define kDescendents 37
#define kDescender 38
#define kEncodingScheme 39
#define kEndAxis 40
#define kEndCharMetrics 41
#define kEndCompFontMetrics 42
#define kEndComposites 43
#define kEndDescendent 44
#define kEndDirection 45
#define kEndFontMetrics 46
#define kEndKernData 47
#define kEndKernPairs 48
#define kEndMaster 49
#define kEndMasterFontMetrics 50
#define kEndTrackKern 51
#define kEscChar 52
#define kFamilyName 53
#define kFontBBox 54
#define kFontName 55
#define kFullName 56
#define kIsBaseFont 57
#define kIsFixedPitch 58
#define kIsFixedV 59
#define kItalicAngle 60
#define kKP 61
#define kKPH 62
#define kKPX 63
#define kKPY 64
#define kL 65
#define kMappingScheme 66
#define kMasters 67
#define kMetricsSets 68
#define kN 69
#define kNotice 70
#define kPCC 71
#define kStartAxis 72
#define kStartCharMetrics 73
#define kStartCompFontMetrics 74
#define kStartComposites 75
#define kStartDescendent 76
#define kStartDirection 77
#define kStartFontMetrics 78
#define kStartKernData 79
#define kStartKernPairs 80
#define kStartMaster 81
#define kStartMasterFontMetrics 82
#define kStartTrackKern 83
#define kTrackKern 84
#define kUnderlinePosition 85
#define kUnderlineThickness 86
#define kVV 87
#define kVVector 88
#define kVersion 89
#define kW 90
#define kW0 91
#define kW0X 92
#define kW0Y 93
#define kW1 94
#define kW1X 95
#define kW1Y 96
#define kWX 97
#define kWY 98
#define kWeight 99
#define kWeightVector 100
#define kXHeight 101 

