
#import "PGFoundationApp.h"

static PGFoundationApp* app = nil;

////////////////////////////////////////////////////////////////////////////////

void handleSIGTERM(int signal) {
	printf("Caught signal: %d\n",signal);
	[app stop];
}

void setHandleSignal() {
	// handle TERM and INT signals 
//	signal(SIGTERM,handleSIGTERM);
	signal(SIGINT,handleSIGTERM);	  
//	signal(SIGKILL,handleSIGTERM);
//	signal(SIGQUIT,handleSIGTERM);
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
		_stop = NO;
		_returnValue = 0;
		setHandleSignal();
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize stopping = _stop;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)timerFired:(id)theTimer {
	// call the init method
	[self setup];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)stop {
	_stop = YES;
}

-(void)stoppedWithReturnValue:(int)returnValue {
	NSParameterAssert(_stop==YES);
	_returnValue = returnValue;
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

-(int)run {
	// set return value to be positive number
	_stop = NO;
	_returnValue = 0;
	
	// schedule
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && _stop==NO);

#ifdef DEBUG
	printf("returnValue=%d\n",_returnValue);
#endif

	// return the code
	return _returnValue;
}

-(void)setup {
	// do nothing - needs override
}

@end
