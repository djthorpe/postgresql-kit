
#import "PGFoundationApp.h"
#import <PGServerKit/PGServerKit.h>

@interface PGFoundationServer : PGFoundationApp <PGServerDelegate>

// properties
@property PGServer* server;
@property (readonly) NSString* dataPath;
//@property NSUInteger port;
//@property NSString* hostname;

@end
