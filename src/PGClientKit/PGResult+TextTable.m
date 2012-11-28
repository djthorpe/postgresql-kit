//
//  PGResult+TextTable.m
//  postgresql-kit
//
//  Created by David Thorpe on 28/11/2012.
//
//

#import "PGResult+TextTable.h"

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
	[self setRowNumber:0];
	NSArray* row = nil;
	while((row = [self fetchRowAsArray])) {
		[table addObject:[self _rowAsString:row columnWidth:columnWidth delimiter:'|' padding:' ']];
	}

	// add footer
	[table addObject:[self _rowAsString:[NSArray array] columnWidth:columnWidth delimiter:'+' padding:'-']];

	// return ascii table
	[self setRowNumber:oldCurrentRow];
	return [table componentsJoinedByString:@"\n"];
}
@end
