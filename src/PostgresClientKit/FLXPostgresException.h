
#import <Foundation/Foundation.h>

@interface FLXPostgresException : NSException {

}

+(void)raise:(NSString* )theName connection:(void* )theConnection;
+(void)raise:(NSString* )theName reason:(NSString* )theReason;

@end
