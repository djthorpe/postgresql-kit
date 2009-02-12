
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresPrefPaneServerApp : NSObject {
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
-(FLXServerState)serverState;

-(void)startServer;
-(void)stopServer;

@end
