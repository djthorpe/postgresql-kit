
typedef enum {
	PGServerStateUnknown = 0,
	PGServerStateAlreadyRunning, // server is already running
	PGServerStateIgnition,   // fire up the database
	PGServerStateInitialize, // initializing the data directory
	PGServerStateStarting,   // starting the server
	PGServerStateRunning,    // server is running
	PGServerStateStopping,   // stopping the server
	PGServerStateStopped,    // stopped the server
	PGServerStateError       // error occurred
} PGServerState;

#import <Foundation/Foundation.h>
#import "PGServer.h"

// PGServerDelegate
@interface NSObject (PGServerDelegate)
-(void)pgserverState:(PGServerState)theState;
-(void)pgserverMessage:(NSString* )theMessage;
@end
