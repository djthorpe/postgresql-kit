

@interface FLXPostgresServer : NSObject {
  FLXServerState m_theState;
  FLXServerState m_theBackupState;
  NSString* m_theDataPath;
  int m_theProcessIdentifier;
  NSString* m_theHostname;
  NSUInteger m_thePort;
  id m_theDelegate;
}

@property (readonly) NSString* dataPath;
@property (retain) NSString* hostname;
@property (readonly) NSString* serverVersion;
@property (assign) NSUInteger port;
@property (assign) id delegate;
@property (readonly) int processIdentifier;
@property (readonly) FLXServerState state;
@property (readonly) FLXServerState backupState;
@property (readonly) NSString* stateAsString;
@property (readonly) NSString* backupStateAsString;
@property (readonly) BOOL isRunning;

// return shared server object
+(FLXPostgresServer* )sharedServer;

// other properties
+(NSUInteger)defaultPort;
+(NSString* )superUsername;
+(NSString* )backupFileSuffix;

	
// methods - start/stop server
-(BOOL)startWithDataPath:(NSString* )thePath;
-(BOOL)stop;

// reload configuration files
-(BOOL)reload;

// methods - backup database
-(NSString* )backupToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;
-(BOOL)backupInBackgroundToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;

@end
