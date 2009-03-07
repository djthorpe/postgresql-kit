
@interface PostgresServerKeychain : NSObject {
	NSString* dataPath;
	NSString* serviceName;
	id delegate;
	SecKeychainRef keychain;
}

@property (retain) NSString* dataPath;
@property (retain) NSString* serviceName;
@property (assign) id delegate;
@property (assign) SecKeychainRef keychain;

-(id)initWithDataPath:(NSString* )dataPath serviceName:(NSString* )serviceName;
-(BOOL)open;
-(void)close;
-(BOOL)setPassword:(NSString* )thePassword forAccount:(NSString* )theAccount;
-(NSString* )passwordForAccount:(NSString* )theAccount;

@end

@interface NSObject (PostgresServerKeychainDelegate)
-(void)keychainError:(NSError* )theError;
@end