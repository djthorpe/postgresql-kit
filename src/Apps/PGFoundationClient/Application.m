
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

	NSProcessInfo* process = [NSProcessInfo processInfo];
	NSArray* arguments = [process arguments];
	NSParameterAssert([arguments count]);
	
	if([arguments count] < 2) {
		NSLog(@"Error: missing URL");
		return -1;
	}
	
	// connect to database
	NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:1]];
	NSError* error = nil;
	[[self db] connectWithURL:url error:&error];
	if(error) {
		NSLog(@"Error: %@",error);
		return -1;
	}

	// create database
	PGResult* r = [[self db] execute:@"SELECT $1::int" value:@"1000" error:&error];
	NSLog(@"r=%@",[r tableWithWidth:80]);
	
	// disconnect from database 
	[[self db] disconnect];
	
	return 0;
}

@end
