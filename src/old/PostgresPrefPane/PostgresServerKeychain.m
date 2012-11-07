
#import "PostgresServerKeychain.h"

@implementation PostgresServerKeychain
@synthesize serviceName;
@synthesize dataPath;
@synthesize delegate;
@synthesize keychain;

/////////////////////////////////////////////////////////////////////////////////

-(id)initWithDataPath:(NSString* )theDataPath serviceName:(NSString* )theServiceName {
	self = [super init];
	if (self != nil) {
		[self setServiceName:theServiceName];
		[self setDataPath:theDataPath];
		[self setDelegate:nil];
		[self setKeychain:nil];
	}
	return self;
}

-(void)dealloc {
	[self close];
	[self setKeychain:nil];
	[self setServiceName:nil];
	[self setDataPath:nil];	
	[self setDelegate:nil];
	[super dealloc];
}

/////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_delegateErrorWithCode:(OSStatus)theCode message:(NSString* )theMessage {
	if([[self delegate] respondsToSelector:@selector(keychainError:)]) {
		NSError* theError = [NSError errorWithDomain:[self serviceName] code:theCode userInfo:[NSDictionary dictionaryWithObject:theMessage forKey:NSLocalizedDescriptionKey]];
		[[self delegate] keychainError:theError];
	}
}

-(void)_delegateError:(NSError* )theError {
	if([[self delegate] respondsToSelector:@selector(keychainError:)]) {
		[[self delegate] keychainError:theError];
	}
}

-(NSString* )_filePath {
	// return path to stored preferences
	return [[self dataPath] stringByAppendingPathComponent:@"postgresql.keychain"];	
}

-(BOOL)_setKeychainPermissions {
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _filePath]]==NO) {
		return NO;
	}
	NSDictionary* theAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:0600] forKey:NSFilePosixPermissions];
	NSError* theError = nil;
	if([[NSFileManager defaultManager] setAttributes:theAttributes ofItemAtPath:[self _filePath] error:&theError]==NO) {
		[self _delegateError:theError];
		return NO;
	}
	return YES;
}

-(SecKeychainRef)_createKeychainWithPassword:(NSString* )thePassword {
	OSStatus theStatus;
	SecKeychainRef theKeychain;
	theStatus = SecKeychainCreate([[self _filePath] UTF8String],[thePassword length],[thePassword UTF8String],NO,nil,&theKeychain);
	if(theStatus != noErr) {
		[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Unable to create keychain: %@",[self _filePath]]];
		return nil;
	}
	if([self _setKeychainPermissions]==NO) {
		CFRelease(theKeychain);
		return nil;
	}
	return theKeychain;
}

-(BOOL)_addPassword:(NSString* )thePassword forAccount:(NSString* )theAccount {
	NSParameterAssert([self keychain]);	
	// add the password
	OSStatus theStatus = SecKeychainAddGenericPassword([self keychain],[[self serviceName] length],[[self serviceName] UTF8String],[theAccount length],[theAccount UTF8String],[thePassword length],[thePassword UTF8String],nil);
	if(theStatus != noErr) {
		[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Error adding password for account: %@",theAccount]];
		return NO;
	}
	// return success
	return YES;
}

-(BOOL)_deletePasswordForAccount:(NSString* )theAccount {
	NSParameterAssert([self keychain]);	
	do {
		SecKeychainItemRef theItem;
		OSStatus theStatus = SecKeychainFindGenericPassword([self keychain],[[self serviceName] length],[[self serviceName] UTF8String],[theAccount length],[theAccount UTF8String],nil,nil,&theItem);
		if(theStatus == errSecItemNotFound) {
			// reached end of list if items
			break;
		}
		if(theStatus != noErr) {
			[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Error finding password for account: %@",theAccount]];
			return NO;
		}
		theStatus = SecKeychainItemDelete(theItem);
		if(theStatus != noErr) {
			[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Error deleting password for account: %@",theAccount]];
			CFRelease(theItem);
			return NO;			
		}
		CFRelease(theItem);
	} while(1);
	// return success
	return YES;
}

-(NSString* )_passwordForAccount:(NSString* )theAccount {
	NSParameterAssert([self keychain]);	
	SecKeychainItemRef theItem;
	UInt32 thePasswordLength;
	void* thePasswordData;
	OSStatus theStatus = SecKeychainFindGenericPassword([self keychain],[[self serviceName] length],[[self serviceName] UTF8String],[theAccount length],[theAccount UTF8String],&thePasswordLength,&thePasswordData,&theItem);
	if(theStatus == errSecItemNotFound) {
		return nil;
	}
	if(theStatus != noErr) {
		[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Error retrieving password for account: %@",theAccount]];
		return nil;
	}
	NSString* thePassword = [[NSString alloc] initWithBytes:thePasswordData length:thePasswordLength encoding:NSUTF8StringEncoding];
	CFRelease(theItem);	
	return [thePassword autorelease];	
}

/////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)close {
	if([self keychain]) {
		CFRelease([self keychain]);	
		[self setKeychain:nil];
	}
}

-(BOOL)open {
	// no keychain open
	NSParameterAssert([self keychain]==nil);
	
	SecKeychainRef theKeychain;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _filePath]]==NO) {
		// create a new keychain....
		theKeychain = [self _createKeychainWithPassword:@""];
		if(theKeychain==nil) {
			return NO;
		}
	} else {
		// open existing keychain
		OSStatus theStatus = SecKeychainOpen([[self _filePath] UTF8String], &theKeychain);
		if(theStatus != noErr) {
			[self _delegateErrorWithCode:theStatus message:[NSString stringWithFormat:@"Unable to open keychain: %@",[self _filePath]]];
			return NO;
		}
	}
	
	NSParameterAssert(theKeychain);
	
	// set keychain as default
	OSStatus theStatus = SecKeychainSetDefault(theKeychain);
	if(theStatus != noErr) {
		CFRelease(theKeychain);
		[self _delegateErrorWithCode:theStatus message:@"SecKeychainSetDefault error"];
		return NO;
	}

	// set keychain
	[self setKeychain:theKeychain];
	return YES;
}


-(BOOL)setPassword:(NSString* )thePassword forAccount:(NSString* )theAccount {
	BOOL isOpened = NO;
	// see if we need to temporarily open...
	if([self keychain]==nil) {
		isOpened = [self open];
		if(isOpened==NO) {
			return NO;
		}
	}

	NSParameterAssert([self keychain]);

	// delete existing passwords, then add new one
	BOOL isSuccess = [self _deletePasswordForAccount:theAccount];
	if(isSuccess) {
		isSuccess = [self _addPassword:thePassword forAccount:theAccount];
	}
	
	// if temporarily opened, then close
	if(isOpened) {
		[self close];
	}
	// return success condition
	return isSuccess;
}

-(NSString* )passwordForAccount:(NSString* )theAccount {
	BOOL isOpened = NO;
	// see if we need to temporarily open...
	if([self keychain]==nil) {
		isOpened = [self open];
		if(isOpened==NO) {
			return nil;
		}
	}
	
	NSParameterAssert([self keychain]);	
	NSString* thePassword = [self _passwordForAccount:theAccount];
	
	// if temporarily opened, then close
	if(isOpened) {
		[self close];
	}
	// return password or nil on error
	return thePassword;	
}

@end
