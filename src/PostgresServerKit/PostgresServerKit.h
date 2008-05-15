
#import "FLXServer.h"

// delegate
@interface NSObject (FLXServerDelegate)
-(void)serverMessage:(NSString* )theMessage;
-(void)serverStateDidChange:(NSString* )theMessage;
@end
