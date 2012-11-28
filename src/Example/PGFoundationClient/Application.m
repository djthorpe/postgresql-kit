
#import "Application.h"

@implementation Application

-(NSString* )connectionPasswordForParameters:(NSDictionary* )theParameters{
	NSLog(@"returning nil for password, parameters = %@",theParameters);
	return nil;
}

-(void)connectionNotice:(NSString* )theMessage {
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
	static BOOL isConnectionDone = NO;
	
	// stop run loop
	if([self signal] < 0) {
		CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
		return;
	}
	
	// connect to server
	if([self db]==nil) {
		[self setDb:[[PGConnection alloc] init]];
		[[self db] setDelegate:self];
		NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@/"];
		[[self db] connectInBackgroundWithURL:theURL timeout:0 whenDone:^(PGConnectionStatus status,NSError* error){
			NSLog(@"Connection Done, error = %@",error);
			isConnectionDone = YES;
		}];
		return;
	}
	
	if(isConnectionDone==NO) {
		return;
	}
	
	// check on connection status
	PGConnectionStatus status = [[self db] status];
	if(status != PGConnectionStatusConnected) {
		NSLog(@"Connection is not good (status: %d)",status);
		[self setSignal:-1];
		return;
	}

	// execute to get time
	NSError* theError = nil;
	PGResult* theResult = [[self db] execute:@"SELECT pg_database.datname as Database,pg_user.usename as Owner,pg_encoding_to_char(pg_database.encoding) as Encoding,obj_description(pg_database.oid) as Description FROM pg_database, pg_user WHERE pg_database.datdba = pg_user.usesysid" format:PGClientTupleFormatText error:&theError];
	if(theError) {
		NSLog(@"Error: %@",theError);
		[self setSignal:-1];
		return;
	}
	
	NSLog(@"Result\n%@",[theResult tableWithWidth:70]);
	
	[self setSignal:-1];
}

@end
