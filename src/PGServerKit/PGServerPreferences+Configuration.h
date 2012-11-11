
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

@interface PGServerPreferences (Configuration)

// port value
-(NSUInteger)port;
-(void)setPort:(NSUInteger)value;

// listenAddresses value
-(NSString* )listenAddresses;
-(void)setListenAddresses:(NSString* )value;

@end
