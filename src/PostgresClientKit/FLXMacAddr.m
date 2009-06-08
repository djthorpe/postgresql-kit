
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXMacAddr
@synthesize data;

-(id)init {
	self = [super init];
	if (self != nil) {
		data = [[NSData dataWithBytes:"\0\0\0\0\0\0" length:6] retain];
	}
	return self;
}

-(id)initWithBytes:(const void* )theBytes {
	self = [super init];
	if (self != nil) {
		if(theBytes==nil) {
			return nil;
		}
		data = [[NSData dataWithBytes:theBytes length:6] retain];
	}
	return self;	
}

+(FLXMacAddr* )macAddrWithBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
	return [[[FLXMacAddr alloc] initWithBytes:theBytes] autorelease];
}

-(void)dealloc {
	[data release];
	[super dealloc];
}

-(NSString* )stringValue {
	const uint8_t* ptr = [[self data] bytes];
	return [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",ptr[0],ptr[1],ptr[2],ptr[3],ptr[4],ptr[5]];
}

-(NSString* )description {
	return [self stringValue];
}

-(BOOL)isEqual:(id)anObject {
	if([anObject isKindOfClass:[FLXMacAddr class]]==NO) return NO;
	return [[self data] isEqual:[anObject data]];
}

@end
