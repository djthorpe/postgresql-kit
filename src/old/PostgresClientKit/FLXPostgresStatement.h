
#import <Foundation/Foundation.h>

@interface FLXPostgresStatement : NSObject {
	NSString* statement;
	NSString* name;
}

@property (retain) NSString* statement;
@property (retain) NSString* name;

-(const char* )UTF8Name;
-(const char* )UTF8Statement;

@end
