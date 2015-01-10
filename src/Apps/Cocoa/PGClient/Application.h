
#import <Cocoa/Cocoa.h>
#import "Connection.h"

@interface Application : NSObject <NSApplicationDelegate> {
	Connection* _connection;
}

// properties
@property (readonly) Connection* connection;

@end

