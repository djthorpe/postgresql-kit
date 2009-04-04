
#import <Foundation/Foundation.h>

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

@interface FLXPostgresServer : NSObject {
  FLXServerState m_theState;
  FLXServerState m_theBackupState;
  NSString* m_theDataPath;
  int m_theProcessIdentifier;
  NSString* m_theHostname;
  int m_thePort;
  id m_theDelegate;
}

+(FLXPostgresServer* )sharedServer;

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
+(int)defaultPort;
+(NSString* )superUsername;
+(NSString* )backupFileSuffix;

// properties - determine server/backup state
-(int)processIdentifier;
-(FLXServerState)state;
-(FLXServerState)backupState;
-(NSString* )stateAsString;
-(NSString* )backupStateAsString;
-(BOOL)isRunning;

// methods - start/stop server
-(BOOL)startWithDataPath:(NSString* )thePath;
-(BOOL)stop;
// reload configuration files
-(BOOL)reload;

// methods - backup database
-(NSString* )backupToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;
-(BOOL)backupInBackgroundToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;

@end
