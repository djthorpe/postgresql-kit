
@interface PGPasswordStore : NSObject {
	NSMutableDictionary* _store;
}

// properties
@property (readonly) NSString* serviceName;

// methods
-(NSString* )passwordForURL:(NSURL* )url;
-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError** )error;

@end
