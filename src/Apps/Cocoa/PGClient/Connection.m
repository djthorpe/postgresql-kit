
#import "Connection.h"

@implementation Connection

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [PGConnection new];
		_password = [PGPasswordStore new];
		NSParameterAssert(_connection);
		// set delegate
		[_connection setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize password = _password;
@synthesize useKeychain;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithString:@"postgres://pttnkktdoyjfyc@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5"];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)login {
	if([[self connection] status] != PGConnectionStatusConnected) {
		[[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error) {
			if(error) {
				NSLog(@"Connected, error = %@",error);
			}
		}];
	}
}

-(void)disconnect {
	if([[self connection] status] == PGConnectionStatusConnected) {
		[[self connection] disconnect];
	}	
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate implementation

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	// add username if that's not in the dictionary
	NSString* user = [dictionary objectForKey:@"user"];
	if(![user length]) {
		[dictionary setObject:NSUserName() forKey:@"user"];
	}

	// store and retrieve password
	if([self password]) {
		NSError* error = nil;
		if([dictionary objectForKey:@"password"]) {
			NSError* error = nil;
			[[self password] setPassword:[dictionary objectForKey:@"password"] forURL:[self url] saveToKeychain:[self useKeychain] error:&error];
		} else {
			NSString* password = [[self password] passwordForURL:[self url] error:&error];
			if(password) {
				[dictionary setObject:password forKey:@"password"];
			}
		}
		if(error) {
			NSLog(@"Keychain error: %@",[error localizedDescription]);
		}
	}
	
	// display parameters
	for(NSString* key in dictionary) {
		if([key isEqualToString:@"password"]) {
			continue;
		}
		NSLog(@"%@: %@",key,[dictionary objectForKey:key]);
	}
}

@end
