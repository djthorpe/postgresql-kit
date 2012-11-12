
#import <Foundation/Foundation.h>

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

// forward class declarations
@class PGServer;
@class PGServerPreferences;

// PGServerDelegate protocol
@protocol PGServerDelegate <NSObject>
@optional
-(void)pgserverStateChange:(PGServer* )sender;
-(void)pgserver:(PGServer* )sender message:(NSString* )message;
@end

// include public header files
#import "PGServer.h"
#import "PGServer+Backup.h"
#import "PGServerPreferences.h"
#import "PGServerPreferences+Configuration.h"
