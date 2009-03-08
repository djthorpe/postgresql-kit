
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "Bindings.h"

@interface Controller : NSObject {
	FLXServer* server;
	FLXPostgresConnection* client;
	NSTimer* timer;

	// IBOutlet
	IBOutlet Bindings* bindings;
}

@property (retain) FLXServer* server;
@property (retain) FLXPostgresConnection* client;
@property (retain) NSTimer* timer;
@property (retain) Bindings* bindings;

@end
