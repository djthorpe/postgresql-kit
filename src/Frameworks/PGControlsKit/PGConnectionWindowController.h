
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum  {
	PGConnectionWindowStatusOK = 100,
	PGConnectionWindowStatusCancel,
	PGConnectionWindowStatusBadParameters,
	PGConnectionWindowStatusNeedsPassword,
	PGConnectionWindowStatusConnecting,
	PGConnectionWindowStatusConnected,
	PGConnectionWindowStatusRejected
} PGConnectionWindowStatus;

////////////////////////////////////////////////////////////////////////////////

@protocol PGConnectionWindowDelegate <NSObject>
@required
	-(void)connectionWindow:(PGConnectionWindowController* )windowController status:(PGConnectionWindowStatus)status;
@optional
	-(void)connectionWindow:(PGConnectionWindowController* )windowController error:(NSError* )error;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController : NSWindowController <PGConnectionDelegate> {
	PGConnection* _connection;
	NSMutableDictionary* _params;
	PGPasswordStore* _password;
	void* _contextInfo;
}

// properties
@property (weak,nonatomic) id<PGConnectionWindowDelegate> delegate;
@property BOOL useKeychain;
@property (readonly) PGPasswordStore* password;
@property (readonly) PGConnection* connection;
@property NSURL* url;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;
-(void)beginPasswordSheetForParentWindow:(NSWindow* )parentWindow;
-(void)beginErrorSheetForParentWindow:(NSWindow* )parentWindow;
-(void)connect;
-(void)disconnect;

@end
