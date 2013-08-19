
#import "PGSidebarNode.h"

@implementation PGSidebarNode

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	return nil;
}

-(id)initWithHeader:(NSString* )name {
	self = [super init];
	if(self) {
		_name = name;
		_url = nil;
		_isHeader = YES;
		_isServer = NO;
		_isInternalServer = NO;
		_children = [NSMutableArray array];
		_status = PGSidebarNodeStatusGrey;
	}
	return self;
}

-(id)initWithLocalServerURL:(NSURL* )url {
	self = [super init];
	if(self) {
		_name = [url absoluteString];
		_url = url;
		_isHeader = NO;
		_isServer = YES;
		_isInternalServer = NO;
		_children = nil;
		_status = PGSidebarNodeStatusGrey;
	}
	return self;		
}

-(id)initWithRemoteServerURL:(NSURL* )url {
	self = [super init];
	if(self) {
		_name = [url absoluteString];
		_url = url;
		_isHeader = NO;
		_isServer = YES;
		_isInternalServer = NO;
		_children = nil;
		_status = PGSidebarNodeStatusGrey;
	}
	return self;
}

-(id)initWithInternalServer {
	self = [super init];
	if(self) {
		_name = @"Internal Server";
		_url = nil;
		_isHeader = NO;
		_isServer = YES;
		_isInternalServer = YES;
		_children = nil;
		_status = PGSidebarNodeStatusGrey;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize children = _children;
@synthesize isHeader = _isHeader;
@synthesize isServer = _isServer;
@synthesize isInternalServer = _isInternalServer;
@synthesize name = _name;
@synthesize url = _url;
@synthesize status = _status;
@dynamic image;

-(NSImage* )image {
	switch([self status]) {
		case PGSidebarNodeStatusGreen:
			return [NSImage imageNamed:@"traffic-green"];
		case PGSidebarNodeStatusOrange:
			return [NSImage imageNamed:@"traffic-orange"];
		case PGSidebarNodeStatusRed:
			return [NSImage imageNamed:@"traffic-red"];
		case PGSidebarNodeStatusGrey:
		default:
			return [NSImage imageNamed:@"traffic-grey"];
	}
}

@end
