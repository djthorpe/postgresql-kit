
#import "FLXPostgresServer.h"
#import "FLXPostgresHostAccessTuple.h"

// delegate
@interface NSObject (FLXServerDelegate)
-(void)serverMessage:(NSString* )theMessage;
-(void)serverStateDidChange:(NSString* )theMessage;
-(void)backupStateDidChange:(NSString* )theMessage;
@end
