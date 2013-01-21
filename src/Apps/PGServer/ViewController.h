
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import <PGClientKit/PGClientKit.h>

////////////////////////////////////////////////////////////////////////////////

@protocol ViewControllerDelegate
-(PGServer* )server;
-(PGConnection* )connection;
-(NSWindow* )mainWindow;
@end

////////////////////////////////////////////////////////////////////////////////

@interface ViewController : NSViewController

@property id<ViewControllerDelegate> delegate;
@property NSSize frameSize;
@property (readonly) NSString* identifier;
@property (readonly) NSInteger tag;

// messages sent to ViewController
-(BOOL)willSelectView:(id)sender;
-(BOOL)willUnselectView:(id)sender;

@end
