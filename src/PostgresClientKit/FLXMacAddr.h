
#import <Foundation/Foundation.h>

@interface FLXMacAddr : NSObject {
	NSData* data;
}

@property (retain) NSData* data;

+(FLXMacAddr* )macAddrWithData:(NSData* )theData;
-(NSString* )stringValue;

@end
