
#import <Foundation/Foundation.h>

// state
typedef enum {
	FLXServerStateUnknown = 1,
	FLXServerStateAlreadyRunning,
	FLXServerStateIgnition,
	FLXServerStateInitializing,
	FLXServerStateStarting,
	FLXServerStateStartingError,
	FLXServerStateStarted,
	FLXServerStateStopping,
	FLXServerStateStopped,
	FLXBackupStateIdle,
	FLXBackupStateRunning,
	FLXBackupStateError	
} FLXServerState;

// delegate
@interface NSObject (FLXServerDelegate)
-(void)serverMessage:(NSString* )theMessage;
-(void)serverStateDidChange:(NSString* )theMessage;
-(void)backupStateDidChange:(NSString* )theMessage;
@end

// classes
#import "FLXPostgresServer.h"
#import "FLXPostgresServerAccessTuple.h"
#import "FLXPostgresServer+Access.h"