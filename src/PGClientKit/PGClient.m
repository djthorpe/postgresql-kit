
#import "PGClientKit.h"
#include <libpq-fe.h>

NSString* PGClientScheme = @"pgsql";

@implementation PGClient

-(id)init {
	self = [super init];
	if(self) {
		_connection = nil;
	}
	return self;
}

-(void)dealloc {
	if(_connection) {
		PQfinish(_connection);
	}
}

-(BOOL)connectWithURL:(NSURL* )theURL {
	return [self connectWithURL:theURL timeout:0];
}

-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout {
	// check for existing connection
	if(_connection) {
		return NO;
	}
	return YES;
}

-(BOOL)disconnect {
	if(_connection==nil) {
		return NO;
	}
	PQfinish(_connection);
	_connection = nil;
	return YES;
}

@end
