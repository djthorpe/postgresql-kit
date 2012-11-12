
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

@interface PGServerPreferences (Configuration)

// port value
-(NSUInteger)port;
-(void)setPort:(NSUInteger)value;

// listenAddresses value
-(NSString* )listenAddresses;
-(void)setListenAddresses:(NSString* )value;

// bonjour discovery
//-(BOOL)bonjourEnabled;
//-(NSString* )bonjourServiceName;
//-(void)setBonjourEnabled:(BOOL)enabled serviceName:(NSString* )name;

@end
