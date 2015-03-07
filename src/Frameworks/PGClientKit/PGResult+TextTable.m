
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

@implementation PGResult (TextTable)

-(NSString* )_rowAsString:(NSArray* )row columnWidth:(NSUInteger* )columnWidth delimiter:(char)delim padding:(char)pad {
	NSMutableString* rowString = [NSMutableString string];
	for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
		NSString* value = nil;
		if([row count] > i) {
			value = [[row objectAtIndex:i] description];
		} else {
			value = @"";
		}
		value = [value stringByPaddingToLength:columnWidth[i] withString:[NSString stringWithFormat:@"%c",pad] startingAtIndex:0];
		[rowString appendFormat:@"%c%@",delim,value];
	}
	[rowString appendFormat:@"%c",delim];
	return rowString;
}

-(NSUInteger* )_calculateColumnWidthFrom:(NSUInteger)lineWidth {
	NSUInteger* maxWidth = malloc(sizeof(NSUInteger) * [self numberOfColumns]);
	if(maxWidth==nil) {
		return nil;
	}
	for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
		maxWidth[i] = 0;
	}
	// work out maximum width of each column
	if([self size]) {
		[self setRowNumber:0];
		NSArray* row = nil;
		while((row = [self fetchRowAsArray])) {
			for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
				NSString* value = nil;
				if([row count] > i) {
					value = [[row objectAtIndex:i] description];
				} else {
					value = @"";
				}
				NSUInteger cellWidth = [value length];
				if(cellWidth > maxWidth[i]) {
					maxWidth[i] = cellWidth;
				}
			}
		}
	}
	
	// now loop around until we have added or removed enough so width equals totalwidth
	NSUInteger totalWidth = 0;
	while(totalWidth != lineWidth) {
		totalWidth = 0;
		for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
			totalWidth += maxWidth[i];
		}
		// add or subtract one from maxWidth for each
		for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
			if(totalWidth < lineWidth) {
				maxWidth[i] = maxWidth[i] + 1;
				totalWidth = totalWidth + 1;
			} else if(totalWidth > lineWidth) {
				if(maxWidth[i] > 1) {
					totalWidth = totalWidth - 1;
					maxWidth[i] = maxWidth[i] - 1;
				}
			}
		}
	}
	return maxWidth;
}

-(NSString* )tableWithWidth:(NSUInteger)lineWidth {
	// return nil if no data
	if([self dataReturned]==NO) {
		return nil;
	}
	if([self numberOfColumns]==0) {
		return nil;
	}
	NSUInteger totalWidth = 0;
	NSUInteger oldCurrentRow = [self rowNumber];

	// calculate column widths
	NSUInteger* columnWidth = [self _calculateColumnWidthFrom:(lineWidth - ([self numberOfColumns] + 1))];	
	for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
		totalWidth += (columnWidth[i] + 2);
	}

	// Generate ascii table
	NSMutableArray* table = [NSMutableArray arrayWithCapacity:([self size] + 4)];
	
	// add in header
	[table addObject:[self _rowAsString:[NSArray array] columnWidth:columnWidth delimiter:'+' padding:'-']];
	[table addObject:[self _rowAsString:[self columnNames] columnWidth:columnWidth delimiter:'|' padding:' ']];
	[table addObject:[self _rowAsString:[NSArray array] columnWidth:columnWidth delimiter:'+' padding:'-']];

	// add in rows
	if([self size]) {
		[self setRowNumber:0];
		NSArray* row = nil;
		while((row = [self fetchRowAsArray])) {
			[table addObject:[self _rowAsString:row columnWidth:columnWidth delimiter:'|' padding:' ']];
		}
	}

	// add footer
	[table addObject:[self _rowAsString:[NSArray array] columnWidth:columnWidth delimiter:'+' padding:'-']];

	// return ascii table
	if([self size]) {
		[self setRowNumber:oldCurrentRow];
	}
	return [table componentsJoinedByString:@"\n"];
}
@end
