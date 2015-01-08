
#import "PGFoundationApp.h"

@implementation PGFoundationApp

-(void)timerFired:(id)theTimer {
	// call the init method
	[self setup];
}

-(void)stop {
	// stop
	_returnValue = 0;
}

-(int)run {
	// set return value to be positive number
	_returnValue = 1;
	
	// schedule
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && _returnValue > 0);

	// return the code
	return _returnValue;
}

-(void)setup {
	// do nothing
}

@end
