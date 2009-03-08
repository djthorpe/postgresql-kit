
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "ServerLog.h"

@interface ServerController : NSObject {
	// properties
	BOOL m_isReady;
	
	// outlets
	IBOutlet NSWindow* m_theStartupSheet;
	IBOutlet NSProgressIndicator* m_theProgressIndicator;
	IBOutlet NSTextView* m_theTextView;
	IBOutlet NSTextField* m_theTextField;
}

-(BOOL)isStarted;
-(BOOL)isReady;
-(void)startServerWithWindow:(NSWindow* )theWindow;
-(void)stopServerWithWindow:(NSWindow* )theWindow;

@end
