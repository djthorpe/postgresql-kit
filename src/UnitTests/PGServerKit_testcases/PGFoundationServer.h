
#import <Foundation/Foundation.h>
#import <PGServerKit/PGServerKit.h>

@interface PGFoundationServer : NSObject  <PGServerDelegate> {
	PGServer* _server;
	BOOL _stop;
}

// static methods
+(NSString* )defaultDataPath;

// constructor
-(id)init;
-(id)initWithServer:(PGServer* )server;

// properties
@property (readonly) BOOL isStarted;
@property (readonly) BOOL isStopped;
@property (readonly) BOOL isError;
@property (readonly) NSString* dataPath;

// methods
-(BOOL)start;
-(BOOL)startWithPort:(NSUInteger)port;
-(BOOL)stop;
-(BOOL)deleteData;

@end
