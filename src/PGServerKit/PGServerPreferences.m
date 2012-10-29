
#import "PGServerKit.h"

@implementation PGServerPreferences

-(id)init {
	return nil;
}

-(id)initWithConfigurationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in configuration file
		_data = [self _readFile:path type:PGServerPreferencesTypeConfiguration];
		if(_data==nil) {
			return nil;
		}
		[self setModified:NO];
	}
	return self;
}

-(id)initWithAuthenticationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in authentication file		
		_data = [self _readFile:path type:PGServerPreferencesTypeAuthentication];
		if(_data==nil) {
			return nil;
		}
		[self setModified:NO];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

-(PGServerPreference* )_parseConfigurationLine:(NSString* )line {
	return [[PGServerPreference alloc] initWithLine:line];
}

-(PGServerPreference* )_parseAuthenticationLine:(NSString* )line {
	return [[PGServerPreference alloc] initWithLine:line];
}

-(NSMutableArray* )_readFile:(NSString* )path type:(PGServerPreferencesType)type {
	NSError* theError = nil;
	NSString* theContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&theError];
	if(theContents==nil) {
#ifdef DEBUG
		NSLog(@"_readFile error: %@: %@",path,theError);
#endif
		return nil;
	}
	NSArray* theLines = [theContents componentsSeparatedByString:@"\n"];
	NSMutableArray* theTuples = [NSMutableArray arrayWithCapacity:[theLines count]];
	for(NSString* line in theLines) {
		PGServerPreference* pref = nil;
		switch(type) {
			case PGServerPreferencesTypeConfiguration:
				pref = [self _parseConfigurationLine:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
				break;
			case PGServerPreferencesTypeAuthentication:
				pref = [self _parseAuthenticationLine:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
				break;
		}
		if(pref==nil) {
			// parse error with file - return error
#ifdef DEBUG
			NSLog(@"_readFile parse error: %@",line);
#endif
			return nil;
		} else {
			[theTuples addObject:pref];
		}
	}
	return theTuples;
}

-(NSString* )description {
	return [_data description];
}

@end
