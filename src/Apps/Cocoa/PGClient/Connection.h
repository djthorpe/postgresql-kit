
#import <Foundation/Foundation.h>
#import <PGControlsKit/PGControlsKit.h>

@interface Connection : NSObject <PGConnectionWindowDelegate> {
	PGConnectionWindowController* _connection;
}

// properties
@property (readonly) PGConnectionWindowController* connection;
@property (readonly) NSURL* url;
@property (weak) NSWindow* parentWindow;

// methods
-(void)loginSheetWithWindow:(NSWindow* )window;
-(void)disconnect;

@end
