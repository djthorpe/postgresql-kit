
#import <Cocoa/Cocoa.h>

typedef enum {
	PGSidebarNodeStatusGrey,
	PGSidebarNodeStatusGreen,
	PGSidebarNodeStatusOrange,
	PGSidebarNodeStatusRed
} PGSidebarNodeStatusType;

@interface PGSidebarNode : NSObject {
	NSString* _name;
	NSMutableArray* _children;
	NSURL* _url;
	BOOL _isHeader;
	BOOL _isServer;
	BOOL _isInternalServer;
	PGSidebarNodeStatusType _status;
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
@property PGSidebarNodeStatusType status;
@property NSImage* image;

@end
