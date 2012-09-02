
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

extern uint64 PGServerDefaultPort;

@interface PGServer : NSObject {
	PGServerState _state;
}
@property id delegate;
@property PGServerState state;
@property (copy) NSString* hostname;
@property uint64 port;
@property (retain) NSString* dataPath;
@property (assign) int pid;

// return shared server object
+(PGServer* )sharedServer;

// start server
-(BOOL)startWithDataPath:(NSString* )thePath;
-(BOOL)stop;

// utility methods
+(NSString* )stateAsString:(PGServerState)theState;

@end
