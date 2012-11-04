
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

@end
