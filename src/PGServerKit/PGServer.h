
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

extern NSUInteger PGServerDefaultPort;

@interface PGServer : NSObject {
	PGServerState _state;
	NSString* _hostname;
	NSUInteger _port;
	NSString* _dataPath;
	NSTask* _currentTask;
	NSTimer* _timer;
	int _pid;
	PGServerPreferences* _authentication;
	PGServerPreferences* _configuration;
}

// properties
@property id<PGServerDelegate> delegate;
@property (readonly) NSString* version;
@property (readonly) PGServerState state;
@property (readonly) NSString* hostname;
@property (readonly) NSUInteger port;
@property (readonly) NSString* dataPath;

// return shared server object
+(PGServer* )serverWithDataPath:(NSString* )thePath;

// signal the server to do things
-(BOOL)start; // uses default port, no network
-(BOOL)startWithPort:(NSUInteger)port; // uses custom port, no network
-(BOOL)startWithNetworkBinding:(NSString* )hostname port:(NSUInteger)port;
-(BOOL)stop;
-(BOOL)restart;
-(BOOL)reload;

// configuration
-(PGServerPreferences* )configuration;

// utility methods
+(NSString* )stateAsString:(PGServerState)theState;

@end

