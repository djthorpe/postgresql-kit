
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresServerApp : NSObject {
	NSString* dataPath;
	NSString* backupPath;
	FLXServer* server;
	NSConnection* connection;
	BOOL isRemoteAccess;
	BOOL isBackupEnabled;
	NSTimeInterval backupTimeInterval;
	NSDate* lastBackupTime;
	NSUInteger serverPort;
	NSUInteger defaultServerPort;
	NSTimer* backupTimer;
}

// properties
@property (retain) FLXServer* server;
@property (retain) NSConnection* connection;
@property (retain) NSString* dataPath;
@property (retain) NSString* backupPath;
@property (retain) NSDate* lastBackupTime;
@property (retain) NSTimer* backupTimer;
@property (assign) BOOL isRemoteAccess;
@property (assign) BOOL isBackupEnabled;
@property (assign) NSTimeInterval backupTimeInterval;
@property (assign) NSUInteger serverPort;
@property (assign, readonly) NSUInteger defaultServerPort;

// methods
-(BOOL)awakeThread;
-(void)startServer;
-(void)stopServer;
-(NSString* )serverVersion;
-(FLXServerState)serverState;
-(NSString* )serverStateAsString;
-(NSString* )dataSpaceFreeAsString;
-(void)fireBackupCycle;

@end
