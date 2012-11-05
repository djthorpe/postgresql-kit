
#import "PGServerKit.h"

@implementation PGServerPreferences

-(id)init {
	return nil;
}

-(id)initWithConfigurationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in configuration file
		if([super load:path]==NO) {
			return nil;
		}
	}
	return self;
}

-(id)initWithAuthenticationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in authentication file		
		if([super load:path]==NO) {
			return nil;
		}
	}
	return self;
}


@end
