
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

@interface RemoteConnectionWindowController : NSWindowController {
	PGConnection* _connection;
	NSMutableDictionary* _parameters;
}

// properties
@property (readonly) NSMutableDictionary* parameters;

@property BOOL validParameters;
@property (readonly) NSString* timeoutString;
@property NSImage* statusImage;
@property (readonly) NSURL* url;
@property (assign) IBOutlet NSBox* ibAdvancedOptionsBox;
@property NSTimer* pingTimer;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow url:(NSURL* )url;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
