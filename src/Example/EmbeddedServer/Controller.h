
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface Controller : NSObject {
	FLXServer* server;
	NSTimer* timer;
}

@property (retain) FLXServer* server;
@property (retain) NSTimer* timer;

@end
