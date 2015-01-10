
#import <Cocoa/Cocoa.h>
#import <PGControlsKit/PGControlsKit.h>

#import "Connection.h"

@interface Application : NSObject <NSApplicationDelegate> {
	Connection* _connection;
	PGSplitViewController* _splitview;
}

// properties
@property (readonly) Connection* connection;
@property (readonly) PGSplitViewController* splitView;

@end

