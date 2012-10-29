
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

@interface PGServerPreferences : NSObject

-(id)initWithConfigurationFile:(NSString* )path;
-(id)initWithAuthenticationFile:(NSString* )path;

@end
