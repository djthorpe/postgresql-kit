
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import <PGClientKit/PGClientKit.h>

////////////////////////////////////////////////////////////////////////////////

@protocol ViewControllerDelegate
-(PGServer* )server;
-(PGConnection* )connection;
@end

////////////////////////////////////////////////////////////////////////////////

@interface ViewController : NSViewController

@property id<ViewControllerDelegate> delegate;
@property NSSize frameSize;
@property (readonly) NSString* identifier;

-(BOOL)willSelectView:(id)sender;
-(BOOL)willUnselectView:(id)sender;

@end
