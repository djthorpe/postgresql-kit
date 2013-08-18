
#import <Cocoa/Cocoa.h>

@interface PGSidebarNode : NSObject {
	NSString* _name;
	NSMutableArray* _children;
	BOOL _isHeader;
}

// constructor
-(id)initWithName:(NSString* )name isHeader:(BOOL)isHeader;
-(id)initWithLocalServerURL:(NSURL* )url;

// properties
@property NSMutableArray* children;
@property BOOL isHeader;
@property NSString* name;
@property NSImage* image;

@end
