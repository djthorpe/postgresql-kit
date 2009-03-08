
#import <Foundation/Foundation.h>
#import "TestDelegate.h"

volatile int caughtSignal = 0;

void signalHandler(int signal) {
	caughtSignal = signal;
	if(caughtSignal > 0) {
		CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
	}  
}

int main(int argc,char* argv[]) {
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	int returnValue = 0;
	TestDelegate* theApp = nil;
	
	// catch signals
	signal(SIGTERM,signalHandler);
	
	// create an application object
	theApp = [[TestDelegate alloc] init];
	if([theApp awakeThread]==NO) {
		returnValue = -1;
		goto APP_EXIT;
	}
	
	// start  the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		// run the loop!
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
		// occasionally re-create the autorelease pool whilst program is running
		[thePool release];
		thePool = [[NSAutoreleasePool alloc] init];            
	} while(isRunning==YES && [theApp stopped]==NO && caughtSignal==0);  
	
APP_EXIT:
	[theApp release];
	[thePool release];
	return returnValue;
}