
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

@protocol PGLoginDelegate <NSObject>
@required
-(void)loginCompleted:(NSInteger)returnCode;
@end

@interface PGLoginController : NSWindowController

// properties
@property (weak, nonatomic) id<PGLoginDelegate> delegate;
@property PGConnection* connection;
@property BOOL ibStatusVisibility;
@property BOOL ibRememberCheckbox;
@property NSString* ibStatusText;
@property BOOL ibStatusAnimate;
@property NSString* ibURL;

// methods to begin the login window
-(void)beginLoginSheetForWindow:(NSWindow* )window;

@end
