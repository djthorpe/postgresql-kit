
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "PostgresServerKeychain.h"

@interface PostgresServerApp : NSObject {
	NSString* dataPath;
	NSString* backupPath;
	FLXPostgresServer* server;
	FLXPostgresConnection* client;
	NSConnection* connection;
	BOOL isRemoteAccess;
	BOOL isBackupEnabled;
	NSTimeInterval backupTimeInterval;
	NSDate* lastBackupTime;
	NSInteger backupFreeSpacePercent;
	NSUInteger serverPort;
	NSUInteger defaultServerPort;
	NSTimer* backupTimer;
	PostgresServerKeychain* keychain;
	
}

// properties
@property (retain) FLXPostgresServer* server;
@property (retain) FLXPostgresConnection* client;
@property (retain) NSConnection* connection;
@property (retain) NSString* dataPath;
@property (retain) NSString* backupPath;
@property (retain) NSDate* lastBackupTime;
@property (assign) NSInteger backupFreeSpacePercent;
@property (retain) NSTimer* backupTimer;
@property (assign) BOOL isRemoteAccess;
@property (assign) BOOL isBackupEnabled;
@property (assign) NSTimeInterval backupTimeInterval;
@property (assign) NSUInteger serverPort;
@property (assign, readonly) NSUInteger defaultServerPort;
@property (retain) PostgresServerKeychain* keychain;

// methods
-(BOOL)awakeThread;
-(void)endThread;
-(void)startServer;
-(void)stopServer;
-(NSString* )serverVersion;
-(FLXServerState)serverState;
-(NSString* )serverStateAsString;
-(NSString* )dataSpaceFreeAsString;
-(NSUInteger)dataSpaceFreeAsPercent;
-(void)fireBackupCycle;
-(BOOL)hasSuperuserPassword;
-(BOOL)setSuperuserPassword:(NSString* )theNewPassword existingPassword:(NSString* )theOldPassword;

@end
