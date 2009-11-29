
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* window;
}

@property (assign) IBOutlet NSWindow *window;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;

@end
