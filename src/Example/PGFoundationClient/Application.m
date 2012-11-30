
#import "Application.h"

@implementation Application

-(NSString* )connectionPasswordForParameters:(NSDictionary* )theParameters{
	printf("returning nil for password, parameters = %s\n",[[theParameters description] UTF8String]);
	return nil;
}

-(void)connectionNotice:(NSString* )theMessage {
	printf("Notice: %s\n",[theMessage UTF8String]);
}

-(void)connectionError:(NSError *)theError {
	printf("Error: %s\n",[[theError localizedDescription] UTF8String]);
}

-(int)run {
	[self setDb:[[PGConnection alloc] init]];
	[[self db] setDelegate:self];

	NSURL* url = [NSURL URLWithString:@"pgsql://postgres@/"];
	NSError* error;
	
	// connect to database
	[[self db] connectWithURL:url error:&error];
	
	
	return 0;
}


@end
