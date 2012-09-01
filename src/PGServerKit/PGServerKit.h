
#import <Foundation/Foundation.h>

typedef enum {
	PGServerStateUnknown = 0,
	PGServerStateStopped,
	PGServerStateStarted,
	PGServerStateError
} PGServerState;

@interface PGServerKit : NSObject
@property (assign) id delegate;
@property (assign) uint64 port;
@property (assign) PGServerState state;
@property (retain) NSString* dataPath;
@property (assign) int pid;

// return shared server object
+(PGServerKit* )sharedServer;

// start server
-(BOOL)startWithDataPath:(NSString* )thePath;

@end
