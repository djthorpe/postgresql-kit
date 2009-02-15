
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresServerApp : NSObject {
	NSString* dataPath;
	FLXServer* server;
	NSConnection* connection;
}

// properties
@property (retain) FLXServer* server;
@property (retain) NSConnection* connection;
@property (retain) NSString* dataPath;

// methods
-(BOOL)awakeThread;
-(void)startServer;
-(void)stopServer;
-(NSString* )serverVersion;
-(NSString* )serverState;

@end
