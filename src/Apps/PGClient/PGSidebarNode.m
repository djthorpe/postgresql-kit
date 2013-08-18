
#import "PGSidebarNode.h"

@implementation PGSidebarNode

// constructor
-(id)init {
	return nil;
}

-(id)initWithName:(NSString* )name isHeader:(BOOL)isHeader {
	self = [super init];
	if(self) {
		_name = name;
		_isHeader = isHeader;
		_children = [NSMutableArray array];
	}
	return self;
}

-(id)initWithLocalServerURL:(NSURL* )url {
	self = [super init];
	if(self) {
		_name = [url absoluteString];
		_isHeader = NO;
		_children = nil;
	}
	return self;		
}

// properties
@synthesize name = _name;
@synthesize isHeader = _isHeader;
@synthesize children = _children;
@dynamic image;

-(NSImage* )image {
	return [NSImage imageNamed:@"red"];
}

@end
