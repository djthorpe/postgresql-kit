
#import <Cocoa/Cocoa.h>
#import <PGControlsKit/PGControlsKit.h>

#import "Connection.h"

@interface Application : NSObject <NSApplicationDelegate> {
	Connection* _connection;
	PGSplitViewController* _splitView;
	PGSourceViewController* _sourceView;
}

// properties
@property (readonly) Connection* connection;
@property (readonly) PGSplitViewController* splitView;
@property (readonly) PGSourceViewController* sourceView;

@end

