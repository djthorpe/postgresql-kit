#import <Foundation/Foundation.h>

@interface PGFoundationApp : NSObject {
	int _returnValue;
}

// constructor
+(id)sharedApp;

// call stop when you wish to stop the application
-(void)stop;

// run is called to start the application and will block. will return 0 on
// successful completion
-(int)run;

// setup is called to do one-time initial set-up, you can override this method
-(void)setup;

@end
