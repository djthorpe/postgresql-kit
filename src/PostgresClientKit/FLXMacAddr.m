
#import "FLXMacAddr.h"

@implementation FLXMacAddr
@synthesize data;

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setData:[NSData dataWithBytes:"\0\0\0\0\0\0" length:6]];
	}
	return self;
}

-(id)initWithData:(NSData* )theData {
	self = [super init];
	if (self != nil) {
		if([theData length] != 6) {
			[self release];
			return nil;
		}
		[self setData:theData];
	}
	return self;	
}

+(FLXMacAddr* )macAddrWithData:(NSData* )theData {
	return [[[FLXMacAddr alloc] initWithData:theData] autorelease];
}

-(void)dealloc {
	[self setData:nil];
	[super dealloc];
}

-(NSString* )stringValue {
	const uint8_t* ptr = [[self data] bytes];
	return [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",ptr[0],ptr[1],ptr[2],ptr[3],ptr[4],ptr[5]];
}

-(NSString* )description {
	return [self stringValue];
}

@end
