
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* window;
	NSMutableString* textField;
}

@property (assign) IBOutlet NSWindow* window;
@property (retain) NSMutableString* textField;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;
@property (retain) NSTimer* timer;

@end
