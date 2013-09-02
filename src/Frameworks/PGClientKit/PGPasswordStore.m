
#import "PGPasswordStore.h"

@implementation PGPasswordStore

-(NSString* )passwordForURL:(NSURL* )url {
	return [self passwordForURL:url error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain {
	return [self setPassword:password forURL:url saveToKeychain:saveToKeychain error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError* )error {
	// TODO
	return nil;
}

-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error {
	// TODO
	return nil;
}

@end
