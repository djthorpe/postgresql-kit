
#import <Foundation/Foundation.h>

@interface FLXPostgresStatement : NSObject {
	NSString* name;
}

@property (retain) NSString* name;

-(const char* )UTF8String;

@end
