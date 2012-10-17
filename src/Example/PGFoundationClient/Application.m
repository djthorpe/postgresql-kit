//
//  Application.m
//  postgresql-kit
//
//  Created by David Thorpe on 17/10/2012.
//
//

#import "Application.h"

@implementation Application

-(NSString* )client:(PGClient* )theClient passwordForParameters:(NSDictionary* )theParameters{
	NSLog(@"returning nil for password, parameters = %@",theParameters);
	return nil;
}

-(int)run {
	PGClient* db = [[PGClient alloc] init];

	[db setDelegate:self];
	
	NSLog(@"Connecting");
	NSError* theError = nil;
	BOOL isSuccess = [db connectWithURL:[NSURL URLWithString:@"pgsql://[::1]/"] error:&theError];
	if(theError) {
		NSLog(@"Error: %@",theError);
	}
	NSLog(@"Success = %@",isSuccess ? @"YES" : @"NO");
	NSLog(@"Disconnecting");
	[db disconnect];

	return 0;
}

@end
