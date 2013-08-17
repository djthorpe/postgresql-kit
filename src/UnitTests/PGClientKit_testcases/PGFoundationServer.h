
#import <Foundation/Foundation.h>
#import <PGServerKit/PGServerKit.h>

@interface PGFoundationServer : NSObject  <PGServerDelegate> {
	PGServer* _server;
}

// properties
@property (assign,atomic) BOOL stopServer;
@property (readonly) BOOL isStarted;
@property (readonly) BOOL isStopped;
@property (readonly) BOOL isError;
@property (readonly) NSString* dataPath;

// methods
-(BOOL)start;
-(BOOL)startWithPort:(NSUInteger)port;
-(BOOL)stop;

@end
