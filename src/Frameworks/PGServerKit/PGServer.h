
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

extern NSUInteger PGServerDefaultPort;
extern NSString* PGServerSuperuser;

@interface PGServer : NSObject {
	PGServerState _state;
	NSString* _hostname;
	NSUInteger _port;
	NSString* _dataPath;
	NSString* _socketPath;
	NSTask* _currentTask;
	NSTimer* _timer;
	int _pid;
	NSUInteger _startTime;
}

// properties
@property (weak, nonatomic) id<PGServerDelegate> delegate;
@property (readonly) NSString* version;
@property (readonly) PGServerState state;
@property (readonly) NSString* dataPath;
@property (readonly) NSString* socketPath;
@property (readonly) NSString* hostname;
@property (readonly) NSUInteger port;
@property (readonly) int pid;
@property (readonly) NSTimeInterval uptime;

// return shared server object
+(PGServer* )serverWithDataPath:(NSString* )thePath;

// signal the server to do things
-(BOOL)start; // uses default port, no network
-(BOOL)startWithPort:(NSUInteger)port; // uses custom port, no network
-(BOOL)startWithPort:(NSUInteger)port socketPath:(NSString* )socketPath; // uses custom port and socket path, no network
-(BOOL)startWithNetworkBinding:(NSString* )hostname port:(NSUInteger)port;
-(BOOL)stop;
-(BOOL)restart;
-(BOOL)reload;

// utility methods
+(NSString* )stateAsString:(PGServerState)theState;

@end

