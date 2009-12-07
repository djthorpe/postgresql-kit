
#import "PostgresServerKit.h"

@implementation FLXPostgresServerIdentityTuple

////////////////////////////////////////////////////////////////////////////////

@synthesize group;
@synthesize user;
@synthesize role;
@dynamic isSupergroup;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSArray* )_parseTokens:(NSString* )theLine {
	NSScanner* theScanner = [NSScanner scannerWithString:theLine];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"'\"#"];
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

-(BOOL)_parseLine:(NSString* )theLine {
	NSArray* theTokens = [self _parseTokens:theLine];
	if(theTokens==nil) {
		return NO;
	}
	if([theTokens count] != 3) {
		return NO;
	}

	[self setGroup:[theTokens objectAtIndex:0]];
	[self setUser:[theTokens objectAtIndex:1]];
	[self setRole:[theTokens objectAtIndex:2]];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithLine:(NSString* )theLine {
	self = [super init];
	if(self != nil) {
		BOOL isSuccess = [self _parseLine:theLine];
		if(isSuccess==NO) {
			[self release];
			return nil;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// NSCopying protocol implementation

-(id)copyWithZone:(NSZone *)zone {
	FLXPostgresServerIdentityTuple* theTuple = [[FLXPostgresServerIdentityTuple allocWithZone:zone] init];
	[theTuple setGroup:[self group]];
	[theTuple setUser:[self user]];
	[theTuple setRole:[self role]];
	return theTuple;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(BOOL)isSupergroup {
	return [[self group] isEqual:[FLXPostgresServer superMapname]];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )asString {
	return [NSString stringWithFormat:@"%@\t%@\t%@\n",[self group],[self user],[self role]];
}

-(NSString* )description {
	return [self asString];
}

@end
