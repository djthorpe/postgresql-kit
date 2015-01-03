
#import "PGClientKit.h"
#import "PGClientKit+Private.h"
#import "SSKeychain.h"

@implementation PGPasswordStore

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_store = [[NSMutableDictionary alloc] init];
		
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic serviceName;

-(NSString* )serviceName {
	return [PGConnection defaultURLScheme];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_accountForURL:(NSURL* )url {
	NSParameterAssert(url);
	if([[PGConnection allURLSchemes] containsObject:[url scheme]]==NO) {
		return nil;
	}
	// extract parameters
	NSDictionary* parameters = [url postgresqlParameters];
	if(parameters==nil) {
		return nil;
	}
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity:[parameters count]];
	for(NSString* key in @[ @"host", @"hostaddr", @"user", @"port", @"dbname" ]) {
		NSString* value = [parameters objectForKey:key];
		// special case for port
		if([key isEqualToString:@"port"] && value==nil) {
			value = [NSString stringWithFormat:@"%lu",(unsigned long)PGClientDefaultPort];
		}
		if(value) {
			[parts addObject:[NSString stringWithFormat:@"%@=%@",key,[[value description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
	}
	return [parts componentsJoinedByString:@";"];
}

////////////////////////////////////////////////////////////////////////////////
// retrieve password

-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error {
	// get password from the URL
	NSString* password = [url password];
	if(password && [password length]) {
		return password;
	}
	// get password from the store
	NSString* account = [self _accountForURL:url];
	if(account==nil) {
		[PGConnection createError:error code:PGClientErrorParameters url:url reason:nil];
		return nil;
	}
	password = [_store objectForKey:account];
	if(password && [password length]) {
		return password;
	}
	// get password from the keychain
	password = [SSKeychain passwordForService:[self serviceName] account:account error:error];
	if(password && [password length]) {
		return password;
	}
	return nil;
}

-(NSString* )passwordForURL:(NSURL* )url {
	return [self passwordForURL:url error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain {
	return [self setPassword:password forURL:url saveToKeychain:saveToKeychain error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError** )error {
	NSString* account = [self _accountForURL:url];
	if(account==nil) {
		[PGConnection createError:error code:PGClientErrorParameters url:url reason:nil];
		return NO;
	}

	// store password against account
	[_store setObject:password forKey:account];

	// if we save to keychain
	BOOL returnValue = YES;
	if(saveToKeychain) {
		returnValue = [SSKeychain setPassword:password forService:[self serviceName] account:account error:error];
	}
	
	return returnValue;
}

@end
