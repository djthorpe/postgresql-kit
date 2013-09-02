
#import <Foundation/Foundation.h>

@interface PGPasswordStore : NSObject

-(NSString* )passwordForURL:(NSURL* )url;
-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError* )error;

@end
