
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresServerApp : NSObject {
	NSString* dataPath;
	FLXServer* server;
	NSConnection* connection;
	BOOL isRemoteAccess;
	NSUInteger serverPort;
}

// properties
@property (retain) FLXServer* server;
@property (retain) NSConnection* connection;
@property (retain) NSString* dataPath;
@property (assign) BOOL isRemoteAccess;
@property (assign) NSUInteger serverPort;

// methods
-(BOOL)awakeThread;
-(void)startServer;
-(void)stopServer;
-(NSString* )serverVersion;
-(NSString* )serverState;

@end
