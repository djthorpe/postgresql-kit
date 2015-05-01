
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

#import <PGServerKit/PGServerKit.h>

@implementation PGHostAccessRule

////////////////////////////////////////////////////////////////////////////////
#pragma mark Construcor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)initWithString:(NSString* )string {
	NSParameterAssert(string);
    self = [super init];
    if (self) {
		_conntype = PGHostAccessConnTypeUnknown;
		_databases = [NSArray new];
		_users = [NSArray new];
		_address = nil;
		_authtype = PGHostAccessAuthTypeUnknown;
		_authoptions = [NSDictionary new];
        _comment = nil;
		if([self _parseString:string]==NO) {
			return nil;
		}
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize conntype = _conntype;
@synthesize databases = _databases;
@synthesize users = _users;
@synthesize address = _address;
@synthesize authtype = _authtype;
@synthesize authoptions = _authoptions;
@synthesize comment = _comment;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Class Methods
////////////////////////////////////////////////////////////////////////////////

static NSDictionary* connlookup = nil;
static NSDictionary* authlookup = nil;

+(void)initialize {
	connlookup = @{
		@1: @"local",
		@2: @"host",
		@3: @"hostssl",
		@4: @"hostnossl",
		@"local": @1,
		@"host": @2,
		@"hostssl": @3,
		@"hostnossl": @4
	};
	authlookup = @{
		@1: @"trust",
		@2: @"reject",
		@3: @"md5",
		@4: @"password",
		@5: @"gss",
		@6: @"sspi",
		@7: @"krb5",
		@8: @"ident",
		@9: @"peer",
		@10: @"ldap",
		@11: @"radius",
		@12: @"cert",
		@13: @"pam",
		@"trust": @1,
		@"reject": @2,
		@"md5": @3,
		@"password": @4,
		@"gss": @5,
		@"sspi": @6,
		@"krb5": @7,
		@"ident": @8,
		@"peer": @9,
		@"ldap": @10,
		@"radius": @11,
		@"cert": @12,
		@"pam": @13
	};
}

+(PGHostAccessConnType)_conntypeFromString:(NSString* )string {
	NSParameterAssert(string);
	NSParameterAssert(connlookup);
	NSNumber* conntype = [connlookup objectForKey:string];
	if(conntype==nil || [conntype isKindOfClass:[NSNumber class]]==NO) {
		return PGHostAccessConnTypeUnknown;
	}
	NSParameterAssert([conntype isKindOfClass:[NSNumber class]]);
	return (PGHostAccessConnType)[conntype intValue];
}

+(PGHostAccessAuthType)_authtypeFromString:(NSString* )string {
	NSParameterAssert(string);
	NSParameterAssert(authlookup);
	NSNumber* authtype = [authlookup objectForKey:string];
	if(authtype==nil || [authtype isKindOfClass:[NSNumber class]]==NO) {
		return PGHostAccessAuthTypeUnknown;
	}
	NSParameterAssert([authtype isKindOfClass:[NSNumber class]]);
	return (PGHostAccessAuthType)[authtype intValue];
}

+(NSString* )_stringFromConntype:(PGHostAccessConnType)value {
	NSParameterAssert(connlookup);
	NSString* string = [connlookup objectForKey:[NSNumber numberWithInt:value]];
	if(string==nil || [string isKindOfClass:[NSString class]]==NO) {
		return nil;
	}
	return string;
}

+(NSString* )_stringFromAuthtype:(PGHostAccessAuthType)value {
	NSParameterAssert(authlookup);
	NSString* string = [authlookup objectForKey:[NSNumber numberWithInt:value]];
	if(string==nil || [string isKindOfClass:[NSString class]]==NO) {
		return nil;
	}
	return string;
}

+(NSArray* )_databasesFromString:(NSString* )string {
	// TODO: parse databases
	return [NSArray new];
}

+(NSArray* )_usersFromString:(NSString* )string {
	// TODO: parse users
	return [NSArray new];
}

+(NSDictionary* )_optionsFromTokens:(NSArray* )tokens index:(NSUInteger)index {
	// TODO: parse options
	return [NSDictionary dictionary];
}

+(NSArray* )_tokensFromString:(NSString* )string {
	NSScanner* theScanner = [NSScanner scannerWithString:string];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"\"#"];
    [tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL insideQuotes = NO;
	BOOL isAtEnd = NO;
	NSString* tempString;
	NSMutableString* currentColumn = [NSMutableString string];
	NSMutableArray* tokens = [NSMutableArray arrayWithCapacity:5];
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
					[tokens addObject:[currentColumn copy]];
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
					[tokens addObject:[currentColumn copy]];
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
				[tokens addObject:[currentColumn copy]];
				[currentColumn setString:@""];
			}
		}
	}
	return tokens;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

-(BOOL)_parseString:(NSString* )string {
	NSArray* tokens = [[self class] _tokensFromString:string];
	if([tokens count] < 4) {
		return NO;
	}
	// set the connection type
	_conntype = [PGHostAccessRule _conntypeFromString:[tokens objectAtIndex:0]];
	if(_conntype==PGHostAccessConnTypeUnknown) {
		return NO;
	}
	// set the databases
	_databases = [PGHostAccessRule _databasesFromString:[tokens objectAtIndex:1]];
	if(_databases==nil) {
		return NO;
	}
	// set the users
	_users = [PGHostAccessRule _usersFromString:[tokens objectAtIndex:2]];
	if(_users==nil) {
		return NO;
	}
	// for the local connection type, set the auth method and options
	if(_conntype==PGHostAccessConnTypeLocal) {
		_authtype = [PGHostAccessRule _authtypeFromString:[tokens objectAtIndex:3]];
		if(_authtype==PGHostAccessAuthTypeUnknown) {
			return NO;
		}
		_authoptions = [PGHostAccessRule _optionsFromTokens:tokens index:4];
		return _authoptions ? YES : NO;
	}

	// for remote auto method, determine if it's a hostname
	// TODO: OTHER OPTIONS
	return YES;
}

-(NSData* )dataWithEncoding:(NSStringEncoding)encoding {
	NSMutableString* string = [NSMutableString string];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"#"];
    [tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// output comment
	NSArray* comments = [[self comment] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for(NSString* comment in comments) {
		[string appendString:@"# "];
		[string appendString:[comment stringByTrimmingCharactersInSet:tokenCharactersSet]];
		[string appendString:@"\n"];
	}

	// TODO: add the rest of the lines in here
	
	return [string dataUsingEncoding:encoding];
}

/*
-(NSString* )data {
	NSMutableString* string = [NSMutableString string];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"#"];
    [tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// output comment
	NSArray* comments = [[self comment] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for(NSString* comment in comments) {
		[string appendString:@"# "];
		[string appendString:[theComment stringByTrimmingCharactersInSet:tokenCharactersSet]];
		[string appendString:@"\n"];
	}

	// output line
	if([self isAddressEditable]) {
		[theString appendString:[NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\n",[self type],[self databaseAsString],[self userAsString],[self address],[self methodAndOptionsAsString]]];
	} else {
		[theString appendString:[NSString stringWithFormat:@"%@\t%@\t%@\t%@\n",[self type],[self databaseAsString],[self userAsString],[self methodAndOptionsAsString]]];		
	}	
	return string;
}
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject overrides
////////////////////////////////////////////////////////////////////////////////

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ {%@}>",NSStringFromClass([self class]),@{ }];
}

@end


/* 
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

*/
