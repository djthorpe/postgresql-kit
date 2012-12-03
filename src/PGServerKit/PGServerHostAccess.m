
#import "PGServerHostAccess.h"

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerHostAccessRule

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if (self) {
		_state = 0;
		_comment = NO;
		_enabled = NO;
		_modified = NO;
		_type = nil;
		_address = nil;
		_ipmask = nil;
		_database = [[NSMutableArray alloc] init];
		_user = [[NSMutableArray alloc] init];
		_options = [[NSMutableDictionary alloc] init];
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

-(void)_setType:(const char* )text type:(PGTokenizerType)type {
	NSParameterAssert([[self _allowedTypes] containsObject:[NSString stringWithUTF8String:text]]);
	NSParameterAssert(_type==nil);
	_type = [PGTokenizerValue valueWithText:text type:type];
}

-(void)_setDatabase:(const char* )text type:(PGTokenizerType)type {
	[_database addObject:[PGTokenizerValue valueWithText:text type:type]];
}

-(void)_setUser:(const char* )text type:(PGTokenizerType)type {
	[_user addObject:[PGTokenizerValue valueWithText:text type:type]];
}

-(void)_setAddress:(const char* )text type:(PGTokenizerType)type {
	NSParameterAssert(_address==nil);
	_address = [PGTokenizerValue valueWithText:text type:type];
}

-(void)_setIPMask:(const char* )text type:(PGTokenizerType)type {
	NSParameterAssert(_address != nil);
	NSParameterAssert([_address type]==PGTokenizerIP4Addr || [_address type]==PGTokenizerIP6Addr);
	_ipmask = [PGTokenizerValue valueWithText:text type:type];
}

-(void)_setMethod:(const char* )text type:(PGTokenizerType)type {
	NSParameterAssert([[self _allowedMethods] containsObject:[NSString stringWithUTF8String:text]]);
	NSParameterAssert(_method==nil);
	_method = [PGTokenizerValue valueWithText:text type:type];
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
				[self _setType:text type:type];
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
				[self _setType:text type:type];
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
			[self _setDatabase:text type:type];
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
			[self _setUser:text type:type];
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
				[self _setMethod:text type:type];
				_state = 10;
				return YES;
			} else {
				[self _setAddress:text type:type];
				_state = 7;
				return YES;
			}
		case PGTokenizerHostname:
			[self _setAddress:text type:type];
			_state = 7;
			return YES;
		case PGTokenizerIP4Addr:
		case PGTokenizerIP6Addr:
			[self _setAddress:text type:type];
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
			[self _setIPMask:text type:type];
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
			[self _setIPMask:text type:type];
			_state = 6;
			return YES;
		case PGTokenizerKeyword:
			if([self _isAllowedMethod:text]) {
				[self _setMethod:text type:type];
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
			[self _setIPMask:text type:type];
			_state = 6;
			return YES;
		case PGTokenizerKeyword:
			if([self _isAllowedMethod:text]) {
				[self _setMethod:text type:type];
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
			NSParameterAssert([_options objectForKey:@"_name"]==nil);
			[_options setValue:[NSString stringWithUTF8String:text] forKey:@"_name"];
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
			NSParameterAssert([_options objectForKey:@"_name"]);
			[_options setValue:[PGTokenizerValue valueWithText:text type:type] forKey:[_options objectForKey:@"_name"]];
			[_options removeObjectForKey:@"_name"];
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

#ifdef DEBUG
	// NSLog(@"{%d, %lu} => %s",type,_state,text);
#endif
	
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
	NSMutableArray* stringArray = [NSMutableArray arrayWithCapacity:[_user count]];
	for(PGTokenizerValue* value in _user) {
		[stringArray addObject:[value text]];
	}
	return [stringArray componentsJoinedByString:@","];
}

-(NSString* )_description_database {
	if([_database count]==0) {
		return nil;
	}
	NSMutableArray* stringArray = [NSMutableArray arrayWithCapacity:[_database count]];
	for(PGTokenizerValue* value in _database) {
		[stringArray addObject:[value text]];
	}
	return [stringArray componentsJoinedByString:@","];
}

-(NSString* )_description_options {
	if([_options count]==0) {
		return nil;
	}
	NSMutableArray* stringArray = [NSMutableArray arrayWithCapacity:[_database count]];
	for(NSString* key in _options) {
		PGTokenizerValue* value = [_options objectForKey:key];		
		[stringArray addObject:[NSString stringWithFormat:@"%@=%@",key,[value text]]];
	}
	return [stringArray componentsJoinedByString:@" "];
}

-(NSString* )_description_address {
	if(_address==nil) {
		return nil;
	}
	if([_address type]==PGTokenizerHostname || [_address type]==PGTokenizerKeyword) {
		NSParameterAssert(_ipmask==nil);
		return [_address stringValue];
	}
	if(([_address type]==PGTokenizerIP4Addr || [_address type]==PGTokenizerIP6Addr) && _ipmask==nil) {
		return [_address stringValue];
	}
	if(([_address type]==PGTokenizerIP4Addr || [_address type]==PGTokenizerIP6Addr) && [[_ipmask stringValue] hasPrefix:@"/"]) {
		return [NSString stringWithFormat:@"%@%@",[_address stringValue],[_ipmask stringValue]];
	}
	if([_address type]==PGTokenizerIP4Addr && [_ipmask type]==PGTokenizerIP4Addr) {
		return [NSString stringWithFormat:@"%@ %@",[_address stringValue],[_ipmask stringValue]];
	}
	NSParameterAssert(NO);
	return nil;
}

-(NSString* )description {
	// if this is a comment line, return as a comment
	if(_comment) {
		return [super description];
	}
	
	NSMutableString* line = [[NSMutableString alloc] init];
	
	// add in a hash if line is not enabled
	if(_enabled==NO) {
		[line appendString:@"#"];
	}

	// we expect a 'type'
	NSParameterAssert(_type);
	[line appendFormat:@"%-7s ",[[_type text] UTF8String]];

	// database
	NSString* database = [self _description_database];
	NSParameterAssert(database);
	[line appendFormat:@"%-15s ",[database UTF8String]];

	// user
	NSString* user = [self _description_user];
	NSParameterAssert(user);
	[line appendFormat:@"%-15s ",[user UTF8String]];

	// address
	NSString* address = [self _description_address];
	if(address) {
		[line appendFormat:@"%-23s ",[address UTF8String]];
	} else {
		[line appendFormat:@"%-23s ",""];		
	}
	
	// method
	if(_method) {
		[line appendFormat:@"%-7s ",[[_method text] UTF8String]];
	}
	
	// options
	NSString* options = [self _description_options];
	if(options) {
		[line appendFormat:@"%@",options];
	}
	
	return line;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic type;
@dynamic method;

-(NSString* )type {
	return _type ? [_type stringValue] : nil;
}

-(void)setType:(NSString* )value {
	NSParameterAssert(value);
	NSParameterAssert([[self _allowedTypes] containsObject:value]);
	_type = [PGTokenizerValue valueWithText:[value UTF8String] type:PGTokenizerKeyword];
	_modified = YES;
}

-(NSString* )method {
	NSParameterAssert(_method);
	return [_method stringValue];
}

-(void)setMethod:(NSString* )value {
	NSParameterAssert(value);
	NSParameterAssert([[self _allowedMethods] containsObject:value]);
	_method = [PGTokenizerValue valueWithText:[value UTF8String] type:PGTokenizerKeyword];
	_modified = YES;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerHostAccess

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithPath:(NSString* )path {
    self = [super initWithPath:path];
    if (self) {
		_rules = [[NSMutableArray alloc] init];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// line factory

-(PGTokenizerLine* )lineFactory {
	return [[PGServerHostAccessRule alloc] init];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(BOOL)modified {
	if([super modified]) {
		return YES;
	}
	for(PGServerHostAccessRule* rule in _rules) {
		if([rule modified]) {
			return YES;
		}
	}
	return NO;
}


////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert([line isKindOfClass:[PGServerHostAccessRule class]]);
	
	// append the line
	if([super append:line]==NO) {
		return NO;
	}
	
	// if this is a rule, then add it to line of rules
	if([(PGServerHostAccessRule* )line type]) {
		[_rules addObject:line];
	}
	
	return YES;
}

-(NSUInteger)count {
	return [_rules count];
}

-(PGServerHostAccessRule* )ruleAtIndex:(NSUInteger)index {
	NSParameterAssert(index < [self count]);
	return [_rules objectAtIndex:index];
}

-(void)removeRuleAtIndex:(NSUInteger)index {
	NSParameterAssert(index < [self count]);
	PGServerHostAccessRule* rule = [self ruleAtIndex:index];
	[super remove:rule];
	[_rules removeObject:rule];
}

-(void)insertRule:(PGServerHostAccessRule* )rule atIndex:(NSUInteger)index {
	NSParameterAssert(rule);
	NSParameterAssert(index >= 0 && index <= ([self count] + 1));
	[_rules insertObject:rule atIndex:index];
}

-(NSUInteger)moveRuleAtIndex:(NSUInteger)index toIndex:(NSUInteger )proposedIndex {
	NSParameterAssert(index < [self count]);
	NSParameterAssert(proposedIndex < ([self count] + 1));
	PGServerHostAccessRule* rule = [self ruleAtIndex:index];
	NSParameterAssert(rule);
	if(proposedIndex==[self count]) {
		// move rule to the end
		NSLog(@"moving rule to end");
		[self removeRuleAtIndex:index];
		[self append:rule];
	} else if(proposedIndex < index) {
		NSLog(@"moving rule to %lu (before current)",proposedIndex);
		[self removeRuleAtIndex:index];
		[self insertRule:rule atIndex:proposedIndex];
	} else if(proposedIndex > index) {
		NSLog(@"moving rule to %lu (after current)",proposedIndex);
		[self removeRuleAtIndex:index];
		[self insertRule:rule atIndex:(proposedIndex-1)];
	}
	return [_rules indexOfObject:rule];
}

@end

