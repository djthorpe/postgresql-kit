
#import "PGFoundationApp.h"

static PGFoundationApp* app = nil;

////////////////////////////////////////////////////////////////////////////////

void handleSIGTERM(int signal) {
	printf("Caught signal: %d\n",signal);
	[app stop];
}

void setHandleSignal() {
	// handle TERM and INT signals 
	signal(SIGTERM,handleSIGTERM);
	signal(SIGINT,handleSIGTERM);	  
	signal(SIGKILL,handleSIGTERM);	  
	signal(SIGQUIT,handleSIGTERM);	  
}

////////////////////////////////////////////////////////////////////////////////

@implementation PGFoundationApp

+(id)sharedApp {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,^{
		app = [[self alloc] init];
	});
	return app;
}

-(id)init {
	self = [super init];
	if(self) {
		_returnValue = 0;
		setHandleSignal();
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)timerFired:(id)theTimer {
	// call the init method
	[self setup];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

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
	// do nothing - needs override
}

@end
