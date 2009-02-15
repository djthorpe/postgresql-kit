
#import <Foundation/Foundation.h>

typedef enum {
  FLXServerStateUnknown = 0,
  FLXServerStateAlreadyRunning = 1,
  FLXServerStateIgnition = 2,
  FLXServerStateInitializing = 3,
  FLXServerStateStarting = 4,
  FLXServerStateStartingError = 5,
  FLXServerStateStarted = 6,
  FLXServerStateStopping = 7,
  FLXServerStateStopped = 8
} FLXServerState;

@interface FLXServer : NSObject {
  FLXServerState m_theState;
  NSString* m_theDataPath;
  int m_theProcessIdentifier;
  NSString* m_theHostname;
  int m_thePort;
  id m_theDelegate;
}

+(FLXServer* )sharedServer;

// delegates
-(void)setDelegate:(id)theDelegate;

// properties - set environment
-(void)setHostname:(NSString* )theHostname;
-(void)setPort:(int)thePort;

// properties - get environment
-(NSString* )dataPath;
-(NSString* )hostname;
-(NSString* )serverVersion;
-(int)port;

// properties - determine server state
-(int)processIdentifier;
-(FLXServerState)state;
-(NSString* )stateAsString;
-(BOOL)isRunning;

// methods
-(BOOL)startWithDataPath:(NSString* )thePath;
-(BOOL)stop;

@end
