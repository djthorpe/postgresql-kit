
#import "PostgresServerKit.h"

@interface FLXPostgresHostAccessTuple (Private)
-(BOOL)_parseLine:(NSString* )theLine;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresHostAccessTuple

////////////////////////////////////////////////////////////////////////////////

@synthesize type;
@synthesize database;
@synthesize user;
@synthesize address;
@synthesize method;
@synthesize option;
@synthesize comment;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setType:@"local"];
		[self setDatabase:@"all"];
		[self setUser:@"all"];
		[self setAddress:@"127.0.0.1"];
		[self setMethod:@"reject"];
		[self setOption:nil];		
		[self setComment:nil];
	}
	return self;
}

-(void)dealloc {
	[self setType:nil];
	[self setDatabase:nil];
	[self setUser:nil];
	[self setAddress:nil];
	[self setMethod:nil];
	[self setOption:nil];
	[self setComment:nil];
	[super dealloc];
}

+(FLXPostgresHostAccessTuple* )hostAccessTupleForLine:(NSString* )theLine {
	FLXPostgresHostAccessTuple* theTuple = [[FLXPostgresHostAccessTuple alloc] init];
	if([theTuple _parseLine:theLine]==NO) {
		[theTuple release];
		return nil;
	} else {
		[theTuple autorelease];
		return theTuple;
	}
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)_parseLineEject:(NSMutableString* )theString state:(NSUInteger* )theState {
	NSString* theToken = [theString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	// comment
	if(*theState==100 || [theToken hasPrefix:@"#"]) {
		*theState = 100;
		return YES;
	}
	switch((*theState)) {
		case 0:
			if([theToken isEqual:@"local"] || [theToken isEqual:@"host"] || [theToken isEqual:@"hostssl"] || [theToken isEqual:@"hostnossl"]) {
				[self setType:theToken];
			} else {
				return NO;
			}
			break;
		case 1:
			[self setDatabase:theToken];
			break;
		case 2:
			[self setUser:theToken];
			break;
		case 3:
			[self setAddress:theToken];
			break;
		case 4:
			[self setMethod:theToken];
			break;
		case 5:
			[self setOption:theToken];
			break;		
		default:
			return NO;
	}
	(*theState)++;
	[theString setString:@""];
	return YES;
}

-(BOOL)_parseLine:(NSString* )theLine {
	NSScanner* theScanner = [NSScanner scannerWithString:theLine];
	[theScanner setCharactersToBeSkipped:nil];
	NSString* theString = nil;
    NSCharacterSet* delimCharactersSet = [NSCharacterSet whitespaceCharacterSet];	
    NSCharacterSet* quoteCharactersSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];	
    NSMutableCharacterSet* delimQuoteCharactersSet = [delimCharactersSet mutableCopy];	
	[delimQuoteCharactersSet formUnionWithCharacterSet:quoteCharactersSet];
	BOOL insideQuotes = NO;
	NSUInteger theState = 0;
	NSMutableString* theToken = [NSMutableString string];
	while([theScanner isAtEnd]==NO) {
		if([theScanner scanCharactersFromSet:delimCharactersSet intoString:&theString]) {
			if(insideQuotes) {
				[theToken appendString:theString];
			} else {
				if([self _parseLineEject:theToken state:&theState]==NO) {
					return NO;
				}
			}
		} else if([theScanner scanCharactersFromSet:quoteCharactersSet intoString:&theString]) {
			[theToken appendString:theString];
			insideQuotes = !insideQuotes;
		} else if([theScanner scanUpToCharactersFromSet:delimQuoteCharactersSet intoString:&theString]) {			
			[theToken appendString:theString];
		} else {
			return NO;
		}
	}
	if(insideQuotes) {
		return NO;
	}
	return [self _parseLineEject:theToken state:&theState];
}


////////////////////////////////////////////////////////////////////////////////


-(NSString* )stringValue {
	NSMutableString* theString = [NSMutableString string];
	// add comment line
	if([self comment]) {
		[theString appendFormat:@"# %@\n",[[self comment] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	// add type - local, host, hostssl, hostnossl
	[theString appendString:[[self type] stringByPaddingToLength:10 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add database
	[theString appendString:[[self database] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add user
	[theString appendString:[[self user] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add address
	[theString appendString:[[self address] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add method
	[theString appendString:[[self method] stringByPaddingToLength:10 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	if([self option]) {
		// add option
		[theString appendString:[[self option] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	}
	[theString appendString:@"\n"];
	// return the string
	return theString;
}

-(NSString* )description {
	return [self stringValue];
}


////////////////////////////////////////////////////////////////////////////////


@end
