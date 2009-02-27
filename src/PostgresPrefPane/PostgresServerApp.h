
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresServerApp : NSObject {
	NSString* dataPath;
	NSString* backupPath;
	FLXServer* server;
	NSConnection* connection;
	BOOL isRemoteAccess;
	NSUInteger serverPort;
	NSUInteger defaultServerPort;
}

// properties
@property (retain) FLXServer* server;
@property (retain) NSConnection* connection;
@property (retain) NSString* dataPath;
@property (retain) NSString* backupPath;
@property (assign) BOOL isRemoteAccess;
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


@end
