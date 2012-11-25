
#import "PGServerHostAccess.h"

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerHostAccessLine

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if (self) {
		_state = 0;
		_comment = NO;
		_enabled = NO;
		_type = nil;
		_host = nil;
		_ip4addr = nil;
		_ip6addr = nil;
		_ipmask = nil;
		_database = [[NSMutableArray alloc] init];
		_user = [[NSMutableArray alloc] init];
		_method = nil;
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
	NSString* type = [NSString stringWithUTF8String:text];
	NSParameterAssert([[self _allowedTypes] containsObject:type]);
	NSParameterAssert(_type==nil);
	_type = type;
}

-(void)_setDatabase:(const char* )text {
	[_database addObject:[NSString stringWithUTF8String:text]];
}

-(void)_setUser:(const char* )text {
	[_user addObject:[NSString stringWithUTF8String:text]];
}

-(void)_setIP4Address:(const char* )text {
	NSParameterAssert(_ip6addr==nil);
	_ip4addr = [NSString stringWithUTF8String:text];
}

-(void)_setIP6Address:(const char* )text {
	NSParameterAssert(_ip4addr==nil);
	_ip6addr = [NSString stringWithUTF8String:text];
}

-(void)_setIPMask:(const char* )text {
	NSParameterAssert(_ip4addr != nil || _ip6addr != nil);
	_ipmask = [NSString stringWithUTF8String:text];
}

-(void)_setHost:(const char* )text {
	NSParameterAssert(_ip4addr == nil && _ip6addr == nil && _ipmask == nil);
	_host = [NSString stringWithUTF8String:text];
}

-(void)_setMethod:(const char* )text {
	NSString* method = [NSString stringWithUTF8String:text];
	NSParameterAssert([[self _allowedMethods] containsObject:method]);
	NSParameterAssert(_method==nil);
	_method = method;
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
			_comment = YES;
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
				_comment = YES;
				_state = 99;
			}
			return YES;
		case PGTokenizerNewline:
			_comment = YES;
			[self setEject:YES];
			return YES;
		default:
			_comment = YES;
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
		case PGTokenizerGroupMap:
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
		case PGTokenizerComma:
			_state = 2;
			return YES;
		case PGTokenizerSQString:
		case PGTokenizerDQString:
		case PGTokenizerKeyword:
		case PGTokenizerGroupMap:			
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
		case PGTokenizerComma:
			_state = 3;
			return YES;
		case PGTokenizerKeyword:
			if([self _isAllowedMethod:text]) {
				[self _setMethod:text];
				_state = 10;
				return YES;
			} else {
				[self _setHost:text];
				_state = 7;
				return YES;
			}
		case PGTokenizerHostname:
			[self _setHost:text];
			_state = 7;
			return YES;
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

// within hostname
-(BOOL)_parse7:(PGTokenizerType)type text:(const char* )text {
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

// after method, before options
-(BOOL)_parse10:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerKeyword:
			NSLog(@"name=%s",text);
			_state = 11;
			return YES;
		default:
			return NO;
	}
}

// after option name, before equals
-(BOOL)_parse11:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerEquals:
			_state = 12;
			return YES;
		default:
			return NO;
	}
}

// after equals, before option value
-(BOOL)_parse12:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerEquals:
			_state = 12;
			return YES;
		case PGTokenizerSQString:
		case PGTokenizerDQString:
		case PGTokenizerOctal:
		case PGTokenizerDecimal:
		case PGTokenizerFloat:
		case PGTokenizerKeyword:
		case PGTokenizerHostname:
		case PGTokenizerIP4Addr:
		case PGTokenizerIP6Addr:
			NSLog(@"value=%s",text);
			_state = 10;
			return YES;
		default:
			return NO;
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
	
	// NSLog(@"{%d, %lu} => %s",type,_state,text);
	
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
		case 7: // within hostname
			return [self _parse7:type text:text];
		case 10: // after method, before options
			return [self _parse10:type text:text];
		case 11: // after option name, before equals
			return [self _parse11:type text:text];
		case 12: // after equals, before option value
			return [self _parse12:type text:text];
		case 99: // continued comment state
			return [self _parse99:type text:text];
		default:
			return NO;
	}
}

////////////////////////////////////////////////////////////////////////////////
// return line

-(NSString* )_description_user {
	if([_user count]==0) {
		return nil;
	}
	return [_user componentsJoinedByString:@","];
}

-(NSString* )_description_database {
	if([_database count]==0) {
		return nil;
	}
	return [_database componentsJoinedByString:@","];
}

-(NSString* )_description_host {
	NSMutableString* host = [[NSMutableString alloc] init];
	if(_ip4addr) {
		NSParameterAssert(_ip6addr==nil);
		[host appendString:_ip4addr];
	} else if(_ip6addr) {
		NSParameterAssert(_ip4addr==nil);
		[host appendString:_ip6addr];
	} else if(_host) {
		NSParameterAssert(_ip6addr==nil && _ip4addr==nil && _ipmask==nil);
		return _host;
	} else {
		NSParameterAssert(_ip6addr==nil && _ip4addr==nil && _ipmask==nil && _host==nil);
		return nil;
	}
	// append the mask
	if(_ipmask && [_ipmask hasPrefix:@"/"]) {
		[host appendString:_ipmask];
	} else {
		[host appendString:@" "];
		[host appendString:_ipmask];
	}
	return host;
}

-(NSString* )description {
	// if this is a comment line, return as a comment
	if(_comment) {
		return [super description];
	}
	
	NSString* host = [self _description_host];
	NSString* user = [self _description_user];
	NSString* database = [self _description_database];
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								_enabled ? @"YES" : @"NO",@"enabled",
								_type ? _type : @"(null)",@"type",
								_method ? _method : @"(null)",@"method",
								host ? host : @"(null)",@"host",
								user ? user : @"(null)",@"user",
								database ? database : @"(null)",@"database",
								nil];
	return [dictionary description];
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
	
	NSLog(@"%@",[line description]);
	
	return YES;
}

@end

