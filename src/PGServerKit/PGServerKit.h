
typedef enum {
	PGServerStateUnknown = 0,
	PGServerStateAlreadyRunning, // server is already running
	PGServerStateIgnition,   // fire up the database
	PGServerStateInitialize, // initializing the data directory
	PGServerStateInitializing, // initializing the data directory
	PGServerStateInitialized,// initialized the data directory
	PGServerStateStarting,   // starting the server
	PGServerStateRunning0,    // server is running - get PID
	PGServerStateRunning,    // server is running
	PGServerStateStopping,   // stopping the server
	PGServerStateStopped,    // stopped the server
	PGServerStateRestart,  	 // signal to restart the server
	PGServerStateError       // error occurred
} PGServerState;

@class PGServer;
@class PGServerPreferences;

#import <Foundation/Foundation.h>
#import "PGServer.h"
#import "PGServer+Backup.h"
#import "PGServerPreferences.h"

// PGServerDelegate
@interface NSObject (PGServerDelegate)
-(void)pgserverStateChange:(PGServer* )sender;
-(void)pgserverMessage:(NSString* )theMessage;
@end
