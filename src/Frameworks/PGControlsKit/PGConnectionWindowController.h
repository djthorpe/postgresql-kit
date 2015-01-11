
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

////////////////////////////////////////////////////////////////////////////////

@protocol PGConnectionWindowDelegate <NSObject>
@required
	-(void)connectionWindow:(PGConnectionWindowController* )windowController endedWithStatus:(NSInteger)status contextInfo:(void* )contextInfo;
@optional
	-(void)connectionWindow:(PGConnectionWindowController* )windowController error:(NSError* )error;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController : NSWindowController <PGConnectionDelegate> {
	PGConnection* _connection;
	NSMutableDictionary* _params;
	PGPasswordStore* _password;
}

// properties
@property (weak,nonatomic) id<PGConnectionWindowDelegate> delegate;
@property (readonly) PGPasswordStore* password;
@property (readonly) PGConnection* connection;
@property NSURL* url;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow contextInfo:(void* )contextInfo;
-(BOOL)connect;
-(void)disconnect;

@end
