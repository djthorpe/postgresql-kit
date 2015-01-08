#import <Foundation/Foundation.h>

@interface PGFoundationApp : NSObject {
	int _returnValue;
}

// methods

// stop is called when you wish to stop the application
-(void)stop;

// run is called to start the application
-(int)run;

// setup is called to do one-time initial set-up
-(void)setup;

@end
