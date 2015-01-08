
#import <Foundation/Foundation.h>

typedef enum {
	PGServerStateUnknown = 0,
	PGServerStateAlreadyRunning0, // server is already running - get PID
	PGServerStateAlreadyRunning, // server is already running
	PGServerStateIgnition,   // fire up the database
	PGServerStateInitialize, // initializing the data directory
	PGServerStateInitializing, // initializing the data directory
	PGServerStateInitialized,// initialized the data directory
	PGServerStateStarting,   // starting the server
	PGServerStateRunning0,    // server is running - get PID
	PGServerStateRunning,    // server is running
	PGServerStateStopping,     // stopping the server
	PGServerStateStopped,     // stopped the server without error
	PGServerStateRestart,  	   // signal to restart the server
	PGServerStateError         // error occurred
} PGServerState;

// forward class declarations
@class PGServer;

// PGServerDelegate protocol
@protocol PGServerDelegate <NSObject>
@optional
-(void)pgserver:(PGServer* )sender stateChange:(PGServerState)state;
-(void)pgserver:(PGServer* )sender message:(NSString* )message;
@end

// include public header files
#import "PGServer.h"

