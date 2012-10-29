//
//  PGServerPreference.m
//  postgresql-kit
//
//  Created by David Thorpe on 29/10/2012.
//
//

#import "PGServerPreference.h"

@implementation PGServerPreference

-(id)init {
	return nil;
}

-(id)initWithLine:(NSString* )line {
	self = [super init];
	if(self) {
		[self setLine:line];
		NSArray* theTokens = [self _parseTokens:line];
		NSLog(@"tokens => %@",theTokens);
	}
	return self;
}

-(NSString* )description {
	return [self line];
}

-(NSArray* )_parseTokens:(NSString* )theLine {
	NSScanner* theScanner = [NSScanner scannerWithString:theLine];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"\"#"];
    [tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL insideQuotes = NO;
	BOOL isAtEnd = NO;
	NSString* tempString;
	NSMutableString* currentColumn = [NSMutableString string];
	NSMutableArray* theTokens = [NSMutableArray arrayWithCapacity:5];
	[theScanner setCharactersToBeSkipped:nil];
    while (isAtEnd==NO) {
		// chew up next bit of the line
		if([theScanner scanUpToCharactersFromSet:tokenCharactersSet intoString:&tempString] ) {
			[currentColumn appendString:tempString];
		}
		// check for end of line
		if([theScanner isAtEnd]) {
			if(insideQuotes) {
				return NO;
			} else {
				// we reached the end of the scanning
				isAtEnd = YES;
				if([currentColumn length]) {
					[theTokens addObject:[currentColumn copy]];
				}
			}
			continue;
		}
		// check for comment
		if([theScanner scanString:@"#" intoString:nil]) {
			if(insideQuotes) {
				[currentColumn appendString:@"#"];
			} else {
				// we reached the end of the scanning
				isAtEnd = YES;
				if([currentColumn length]) {
					[theTokens addObject:[currentColumn copy]];
				}
			}
			continue;
		}
		// check for quotes
		if([theScanner scanString:@"\"" intoString:nil]) {
			if(insideQuotes && [theScanner scanString:@"\"" intoString:nil] ) {
				// Replace double quotes with a single quote in the column string
				[currentColumn appendString:@"\""];
			} else {
				// Start or end of a quoted string.
				insideQuotes = !insideQuotes;
			}
			continue;
		}
		// check for whitespace
		if([theScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&tempString]) {
			if(insideQuotes) {
				[currentColumn appendString:tempString];
			} else {
				// eject token
				[theTokens addObject:[currentColumn copy]];
				[currentColumn setString:@""];
			}
		}
	}
	return theTokens;
}

@end
