
#import "PGServerConfiguration+Helpers.h"

@implementation PGServerConfiguration (Helpers)

-(BOOL)allowsRemoteAccess {
	if([self enabledForKey:@"listen_addresses"]==NO) {
		return NO;
	}
	return YES;
}

-(void)setAllowsRemoteAccess:(BOOL)value {
	if(value==NO) {
		[self setEnabled:NO forKey:@"listen_addresses"];
		[self setString:@"localhost" forKey:@"listen_addresses"];
	} else {
		[self setEnabled:YES forKey:@"listen_addresses"];
		[self setString:@"*" forKey:@"listen_addresses"];
	}
}

@end
