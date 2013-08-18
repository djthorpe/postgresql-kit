
#import <Cocoa/Cocoa.h>

@interface PGSidebarNode : NSObject {
	NSString* _name;
	NSMutableArray* _children;
	NSURL* _url;
	BOOL _isHeader;
	BOOL _isServer;
	BOOL _isInternalServer;
}

// constructor
-(id)initWithHeader:(NSString* )name;
-(id)initWithInternalServer;
-(id)initWithLocalServerURL:(NSURL* )url;
-(id)initWithRemoteServerURL:(NSURL* )url;

// properties
@property (readonly) NSMutableArray* children;
@property (readonly) BOOL isHeader;
@property (readonly) BOOL isServer;
@property (readonly) BOOL isInternalServer;
@property NSString* name;
@property NSURL* url;
@property NSImage* image;

@end
