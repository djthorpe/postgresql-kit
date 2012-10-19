
#import "Application.h"

@implementation Application

-(NSString* )connection:(PGConnection* )theConnection passwordForParameters:(NSDictionary* )theParameters{
	NSLog(@"returning nil for password, parameters = %@",theParameters);
	return nil;
}

-(void)connection:(PGConnection* )theConnection notice:(NSString* )theMessage {
	NSLog(@"Notice: %@",theMessage);	
}

-(int)run {
	[self setSignal:0];
	
	// create a timer
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];

	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && [self signal] >= 0);

	NSLog(@"Disconnecting");
	[[self db] disconnect];

	return [self signal];
}

-(void)timerFired:(id)theTimer {
	// stop run loop
	if([self signal] < 0) {
		CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
		return;
	}
	
	// connect to server
	if([self db]==nil) {
		[self setDb:[[PGConnection alloc] init]];
		[[self db] setDelegate:self];
		
		NSError* theError = nil;
		BOOL isSuccess = [[self db] connectWithURL:[NSURL URLWithString:@"pgsql://postgres@/"] error:&theError];
		if(theError) {
			NSLog(@"Error: %@",theError);
			[self setSignal:-1];
			return;
		}
		if(isSuccess) {
			NSLog(@"Database connected");
			NSLog(@"user=%@",[[self db] user]);
			NSLog(@"database=%@",[[self db] database]);
		}
		return;
	}
	
	// check on connection status
	PGConnectionStatus status = [[self db] status];
	if(status != PGConnectionStatusConnected) {
		NSLog(@"Connection is not good (status: %d)",status);
		return;
	}
	
	// execute to get time
	NSError* theError = nil;
	PGResult* theResult = [[self db] execute:@"SELECT 10 AS value1,'George' AS value2,NULL AS value3" format:PGClientTupleFormatText error:&theError];
	if(theError) {
		NSLog(@"Error: %@",theError);
		[self setSignal:-1];
		return;
	}
	NSLog(@"Result = %@",theResult);
	NSArray* row = nil;
	while((row = [theResult fetchRowAsArray])) {
		NSLog(@"%@",row);
	}
}

@end
