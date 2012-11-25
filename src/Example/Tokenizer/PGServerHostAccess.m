
#import "PGServerHostAccess.h"

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerHostAccessLine

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if (self) {
		_state = 0;
		_enabled = NO;
		_type = nil;
		_database = nil;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSArray* )_allowedTypes {
	return [NSArray arrayWithObjects:@"local",@"host",@"hostssl",@"hostnossl",nil];
}

-(NSArray*)_allowedMethods {
	return [NSArray arrayWithObjects:@"trust",@"reject",@"md5",@"password",@"gss",@"sspi",@"krb5",@"ident",@"peer",@"pam",@"ldap",@"radius",@"cert",nil];
}

-(BOOL)_isAllowedType:(const char* )text {
	return [[self _allowedTypes] containsObject:[NSString stringWithUTF8String:text]];
}

-(BOOL)_isAllowedMethod:(const char* )text {
	return [[self _allowedMethods] containsObject:[NSString stringWithUTF8String:text]];
}

-(void)_setType:(const char* )text {
	NSLog(@"type=>%s",text);
}

-(void)_setDatabase:(const char* )text {
	NSLog(@"database=>%s",text);
}

-(void)_setUser:(const char* )text {
	NSLog(@"user=>%s",text);
}

-(void)_setIP4Address:(const char* )text {
	NSLog(@"ip4addr=>%s",text);
}

-(void)_setIP6Address:(const char* )text {
	NSLog(@"ip6addr=>%s",text);
}

-(void)_setIPMask:(const char* )text {
	NSLog(@"ipmask=>%s",text);
}

-(void)_setMethod:(const char* )text {
	NSLog(@"method=>%s",text);
}

////////////////////////////////////////////////////////////////////////////////
// parser state machine

// start of line state
-(BOOL)_parse0:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerHash:
			_enabled = NO;
			_state = 1;
			return YES;
		case PGTokenizerKeyword:
			_enabled = YES;
			if([self _isAllowedType:text]) {
				[self _setType:text];
				_state = 2;
				return YES;
			} else {
				return NO;
			}
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			return NO;
	}
}

// start of comment state
-(BOOL)_parse1:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			if([self _isAllowedType:text]) {
				[self _setType:text];
				_state = 2;
			} else {
				_state = 99;
			}
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			_state = 99;
			return YES;
	}
}

// after type, before database
-(BOOL)_parse2:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerSQString:
		case PGTokenizerDQString:
		case PGTokenizerKeyword:
			[self _setDatabase:text];
			_state = 3;
			return YES;
		default:
			return NO;
	}
}

// after database, before user
-(BOOL)_parse3:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerSQString:
		case PGTokenizerDQString:
		case PGTokenizerKeyword:
			[self _setUser:text];
			_state = 4;
			return YES;
		default:
			return NO;
	}
}

// after user, before host or method
-(BOOL)_parse4:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerKeyword:
			if([self _isAllowedMethod:text]) {
				[self _setMethod:text];
				_state = 10;
				return YES;
			} else {
				return NO;
			}
		case PGTokenizerIP4Addr:
			[self _setIP4Address:text];
			_state = 5;
			return YES;
		case PGTokenizerIP6Addr:
			[self _setIP6Address:text];
			_state = 5;
			return YES;
		default:
			return NO;
	}
}

// after host, before optional mask
-(BOOL)_parse5:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			_state = 6;
			return YES;
		case PGTokenizerIPMask:
			[self _setIPMask:text];
			_state = 6;
			return YES;
			
		default:
			return NO;
	}
}

// after host & optional mask, before mask or method
-(BOOL)_parse6:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			_state = 6;
			return YES;
		case PGTokenizerIP4Addr:
			[self _setIPMask:text];
			_state = 6;
			return YES;
		case PGTokenizerKeyword:
			if([self _isAllowedMethod:text]) {
				[self _setMethod:text];
				_state = 10;
				return YES;
			} else {
				return NO;
			}			
		default:
			return NO;
	}
}

-(BOOL)_parse10:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;			
		default:
			NSLog(@"do stuff with %s",text);
			return YES;
	}
}

-(BOOL)_parse99:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			return YES;
	}
}

-(BOOL)parse:(PGTokenizerType)type text:(const char* )text {
	// append to _line if not newline character
	if(type != PGTokenizerNewline) {
		[super append:text];
	}
	
	NSLog(@"{%d, %lu} => %s",type,_state,text);
	
	// parse
	switch(_state) {
		case 0: // start of line state
			return [self _parse0:type text:text];
		case 1: // start of comment state
			return [self _parse1:type text:text];
		case 2: // after type, before database
			return [self _parse2:type text:text];
		case 3: // after database, before user
			return [self _parse3:type text:text];
		case 4: // after user, before host
			return [self _parse4:type text:text];
		case 5: // after host, before method
			return [self _parse5:type text:text];
		case 6: // after host & optional mask, before mask or method
			return [self _parse6:type text:text];
		case 10: // after method, before options
			return [self _parse10:type text:text];
		case 99: // continued comment state
			return [self _parse99:type text:text];
		default:
			return NO;
	}
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerHostAccess

// line factory
-(PGTokenizerLine* )makeLine {
	return [[PGServerHostAccessLine alloc] init];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert([line isKindOfClass:[PGServerHostAccessLine class]]);
	
	// append the line
	if([super append:line]==NO) {
		return NO;
	}
	
	return YES;
}

@end

