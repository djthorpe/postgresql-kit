
#import <Cocoa/Cocoa.h>


@interface Bindings : NSObject {
	NSString* output;
	NSString* input;
	BOOL isInputEnabled;
}

@property (retain) NSString* output;
@property (retain) NSString* input;
@property (assign) BOOL isInputEnabled;

@end
