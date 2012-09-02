
/*
 This example shows how to use the PGServerKit to create a server, as
 a foundation shell tool. When the server is started, any signal (TERM or KILL)
 is handled to stop the server gracefully.
*/

#import <Foundation/Foundation.h>
#import <PGServerKit/PGServerKit.h>

////////////////////////////////////////////////////////////////////////////////
// application class

@interface PGFoundationServer : NSObject {
	int signal;
	int returnValue;
}

@property int signal;
@property int returnValue;
@property (readonly) NSString* dataPath;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGFoundationServer
@synthesize signal;
@synthesize returnValue;
@dynamic dataPath;

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

-(PGServer* )server {
	return [PGServer sharedServer];
}

-(void)pgserverMessage:(NSString* )theMessage {
	NSLog(@"Message: %@",theMessage);
}

-(void)pgserverState:(PGServerState)theState {
	NSLog(@"State: %@",[PGServer stateAsString:theState]);
}

-(int)runLoop {
	// set server delegate
	[[self server] setDelegate:self];

	// set success return value
	[self setReturnValue:0];

	// create a timer
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
	} while(isRunning==YES && [self signal] >= 0); 

	return [self returnValue];
}

-(void)timerFired:(id)theTimer {
	
	// stop server if it is already running
	if([[self server] state]==PGServerStateRunning) {
		[[self server] stop];
		return;
	}
	
	// start server if state is unknown
	if([[self server] state]==PGServerStateUnknown) {
		BOOL isStarting = [[self server] startWithDataPath:[self dataPath]];
		if(isStarting==NO) {
			[self setReturnValue:-1];
			[[self server] stop];
		}
		return;
	}
	
	// if server is stopped, then make signal minus 1, and stop the run loop now
	if([[self server] state]==PGServerStateStopped) {
		[self setSignal:-1];
		CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
		return;
	}
	
	// stop server if signal is greater than 0
	if([self signal] > 0) {
		NSLog(@"Received stop signal, stopping server");
		[[self server] stop];
	}
}

@end

////////////////////////////////////////////////////////////////////////////////

static PGFoundationServer* delegate = nil;

void handleSIGTERM(int signal) {
	[delegate setSignal:signal];
}

void setHandleSignal() {
	// handle TERM and INT signals 
	signal(SIGTERM,handleSIGTERM);
	signal(SIGINT,handleSIGTERM);	  
	signal(SIGKILL,handleSIGTERM);	  
	signal(SIGQUIT,handleSIGTERM);	  
}

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		// handle signals
		setHandleSignal();
		// delegate object
		delegate = [[PGFoundationServer alloc] init];
		// run loop
		returnValue = [delegate runLoop];
	}

    return returnValue;
}
