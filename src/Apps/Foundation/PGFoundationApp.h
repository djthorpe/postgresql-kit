#import <Foundation/Foundation.h>

@interface PGFoundationApp : NSObject {
	BOOL _stop;
	int _returnValue;
}

// constructor
+(id)sharedApp;

// run is called to start the application and will block. will return 0 on
// successful completion, or error code otherwise
-(int)run;

// setup is called to do one-time initial set-up, you can override this method
-(void)setup;

// call stop when you wish to stop the application
-(void)stop;

// you should call stopped when the application is finally stopped
-(void)stoppedWithReturnValue:(int)returnValue;

@end
