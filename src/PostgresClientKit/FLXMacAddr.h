
#import <Foundation/Foundation.h>

@interface FLXMacAddr : NSObject {
	NSData* data;
}

@property (retain) NSData* data;

-(id)initWithBytes:(const void* )theBytes;
-(NS

@end
