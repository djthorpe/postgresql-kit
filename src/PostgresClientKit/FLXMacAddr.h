
#import <Foundation/Foundation.h>

@interface FLXMacAddr : NSObject {
	NSData* data;
}

@property (retain,readonly) NSData* data;

+(FLXMacAddr* )macAddrWithBytes:(const void* )theBytes;
-(NSString* )stringValue;

@end
