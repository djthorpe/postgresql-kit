
#import "PostgresServerKit.h"

@implementation FLXPostgresServerAccessTuple
@synthesize comment;
@synthesize type;
@synthesize database;
@synthesize user;	
@synthesize address;	
@synthesize method;	
@synthesize options;	
@dynamic isAddressEditable;
@dynamic isOptionsEditable;
@dynamic isEditable;
@dynamic isSuperadminAccess;
@dynamic textColor;

static FLXPostgresServerAccessTuple* FLXSuperadminTuple = nil;
static FLXPostgresServerAccessTuple* FLXDefaultTuple = nil;

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
	if([theTokens count] < 3) {
		return NO;
	}
	
	// type should be "local", "host" or "hostnossl"
	// we don't support hostssl yet...
	[self setType:[theTokens objectAtIndex:0]];
	if([[self type] isEqual:@"local"]) {
		// requires four or five parameters
		if([theTokens count]==4) {			
			[self setMethod:[theTokens objectAtIndex:3]];		
		} else if([theTokens count]==5) {			
			[self setMethod:[theTokens objectAtIndex:3]];
			[self setOptions:[theTokens objectAtIndex:4]];			
		} else {
			return NO;
		}		
	} else if([[self type] isEqual:@"host"] || [[self type] isEqual:@"hostnossl"] ) {
		// requires five or six parameters
		if([theTokens count]==5) {			
			[self setAddress:[theTokens objectAtIndex:3]];
			[self setMethod:[theTokens objectAtIndex:4]];		
		} else if([theTokens count]==6) {			
			[self setAddress:[theTokens objectAtIndex:3]];
			[self setMethod:[theTokens objectAtIndex:4]];		
			[self setOptions:[theTokens objectAtIndex:5]];			
		} else {
			return NO;
		}		
	} else {
		return NO;
	}
	
	// database and user are always tokens 1 and 2
	[self setDatabase:[theTokens objectAtIndex:1]];
	[self setUser:[theTokens objectAtIndex:2]];

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

+(FLXPostgresServerAccessTuple* )superadmin {
	if(FLXSuperadminTuple == nil) {
		FLXSuperadminTuple = [[FLXPostgresServerAccessTuple alloc] init];
		[FLXSuperadminTuple setType:@"local"];
		[FLXSuperadminTuple setDatabase:@"all"];
		[FLXSuperadminTuple setUser:[FLXPostgresServer superUsername]];
		[FLXSuperadminTuple setMethod:@"ident"];
		[FLXSuperadminTuple setOptions:[NSString stringWithFormat:@"map=%@",[FLXPostgresServer superMapname]]];
		[FLXSuperadminTuple setComment:@"Superadmin access for PostgresServerKit"];
	}
	return FLXSuperadminTuple;
}

+(FLXPostgresServerAccessTuple* )hostpassword {
	if(FLXDefaultTuple==nil) {		
		FLXDefaultTuple = [[FLXPostgresServerAccessTuple alloc] init];
		[FLXDefaultTuple setType:@"host"];
		[FLXDefaultTuple setDatabase:@"all"];
		[FLXDefaultTuple setUser:@"all"];
		[FLXDefaultTuple setAddress:@"127.0.0.1/32"];
		[FLXDefaultTuple setMethod:@"password"];
		[FLXDefaultTuple setComment:@"Password authentication TCP/IP connected users"];
	}
	return FLXDefaultTuple;
}

////////////////////////////////////////////////////////////////////////////////
// NSCopying protocol implementation

-(id)copyWithZone:(NSZone *)zone {
	FLXPostgresServerAccessTuple* theTuple = [[FLXPostgresServerAccessTuple allocWithZone:zone] init];
	[theTuple setType:[self type]];
	[theTuple setDatabase:[self database]];
	[theTuple setUser:[self user]];
	[theTuple setAddress:[self address]];
	[theTuple setMethod:[self method]];
	[theTuple setOptions:[self options]];
	[theTuple setComment:[self comment]];
	return theTuple;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(BOOL)isAddressEditable {
	if([self isEditable]==NO) {
		return NO;
	}
	if([[self type] isEqual:@"local"]) {
		return NO;
	} else {
		return YES;
	}
}

-(BOOL)isOptionsEditable {
	if([self isEditable]==NO) {
		return NO;
	}
	if([[self method] isEqual:@"ident"]) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isEditable {
	if([self isEqual:FLXSuperadminTuple]==YES) {
		return NO;
	} else {
		return YES;
	}
}

-(BOOL)isSuperadminAccess {
	return [self isEqual:[FLXPostgresServerAccessTuple superadmin]];
}

-(NSColor* )textColor {
	if([self isEditable]) {
		return [NSColor blackColor];
	} else {
		return [NSColor grayColor];
	}
}

-(NSString* )databaseAsString {
	if([[self database] isEqual:@"all"] || [[self database] isEqual:@"sameuser"] || [[self database] isEqual:@"samerole"]) {
		return [self database];
	} else {
		return [NSString stringWithFormat:@"\"%@\"",[self database]];
	}
}

-(NSString* )userAsString {
	if([[self user] isEqual:@"all"]) {
		return [self user];
	} else {
		return [NSString stringWithFormat:@"\"%@\"",[self user]];
	}
}

-(NSString* )methodAndOptionsAsString {
	if([[self method] isEqual:@"ident"]) {
		if([[self options] length]) {
			return [NSString stringWithFormat:@"%@\t%@",[self method],[[self options] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		} else {
			return [self method];			
		}
	} else {
		return [self method];
	}	
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )asString {
	NSMutableString* theString = [NSMutableString string];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"#"];
    [tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// output comment
	NSArray* theComments = [[self comment] componentsSeparatedByString:@"\n"];
	for(NSString* theComment in theComments) {
		NSString* theComment2 = [theComment stringByTrimmingCharactersInSet:tokenCharactersSet];
		[theString appendString:@"# "];
		[theString appendString:theComment2];
		[theString appendString:@"\n"];
	}
	
	if([self isAddressEditable]) {
		[theString appendString:[NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\n",[self type],[self databaseAsString],[self userAsString],[self address],[self methodAndOptionsAsString]]];
	} else {
		[theString appendString:[NSString stringWithFormat:@"%@\t%@\t%@\t%@\n",[self type],[self databaseAsString],[self userAsString],[self methodAndOptionsAsString]]];		
	}	
	return theString;
}

-(BOOL)isEqual:(id)anObject {
	if([anObject isKindOfClass:[FLXPostgresServerAccessTuple class]]==NO) return NO;
	FLXPostgresServerAccessTuple* theTuple = (FLXPostgresServerAccessTuple* )anObject;
	if([[self type] isEqual:[theTuple type]]==NO) return NO;
	if([[self database] isEqual:[theTuple database]]==NO) return NO;
	if([[self user] isEqual:[theTuple user]]==NO) return NO;
	if([[self methodAndOptionsAsString] isEqual:[theTuple methodAndOptionsAsString]]==NO) return NO;

	if([[self type] isEqual:@"local"]==NO) {
		if([[self address] isEqual:[theTuple address]]==NO) return NO;
	}
	return YES;
}

-(NSString* )description {
	return [self asString];
}
			
@end
