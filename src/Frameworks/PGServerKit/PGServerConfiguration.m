
#import "PGServerConfiguration.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGServerConfigurationKeyValue
////////////////////////////////////////////////////////////////////////////////

@implementation PGServerConfigurationKeyValue

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if (self) {
		_state = 0;
		_enabled = NO;
		_modified = NO;
		_key = nil;
		_value = nil;
		_comment = [[NSMutableString alloc] init];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)_setKey:(const char* )text {
	if(_key != nil) {
		return NO;
	} else {
		_key = [NSString stringWithUTF8String:text];
		return YES;
	}
}

-(BOOL)_setValue:(PGTokenizerValue* )value {
	if(_value != nil) {
		return NO;
	} else {
		_value = value;
		return YES;
	}
}

////////////////////////////////////////////////////////////////////////////////
// parser state machine

-(BOOL)_parse0:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerHash:
			_enabled = NO;
			_state = 1;
			return YES;
		case PGTokenizerKeyword:
			_enabled = YES;
			[self _setKey:text];
			_state = 2;
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			return NO;
	}
}

-(BOOL)_parse1:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			[self _setKey:text];
			_state = 2;
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			_state = 4;
			return YES;
		default:
			return YES;
	}
}

-(BOOL)_parse2:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerEquals:
			_state = 3;
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		default:
			return YES;
	}
}

-(BOOL)_parse3:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerSQString:
		case PGTokenizerDQString:
		case PGTokenizerOctal:
		case PGTokenizerDecimal:
		case PGTokenizerFloat:
		case PGTokenizerHostname:
		case PGTokenizerIP4Addr:
		case PGTokenizerIP6Addr:
		case PGTokenizerIPMask:
		case PGTokenizerGroupMap:
			return [self _setValue:[PGTokenizerValue valueWithText:text type:type]];
		case PGTokenizerKeyword:
			if(strcasecmp(text,"on")==0 || strcasecmp(text,"off")==0) {
				return [self _setValue:[PGTokenizerValue valueWithText:text type:PGTokenizerBool]];
			} else {
				return [self _setValue:[PGTokenizerValue valueWithText:text type:PGTokenizerKeyword]];
			}
			return YES;
		case PGTokenizerHash:
			_state = 4;
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		default:
			return YES;
	}
}

-(BOOL)_parse4:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			[_comment appendString:[NSString stringWithUTF8String:text]];
			return YES;
	}
}

-(BOOL)_parse5:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			NSLog(@"TODO: add suffix %s",text);
			//[_value setSuffix:[NSString stringWithUTF8String:text]];
			return YES;
		case PGTokenizerHash:
			_state = 4;
			return YES;
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		default:
			return NO;
	}
}

-(BOOL)parse:(PGTokenizerType)type text:(const char* )text {
	// append to _line if not newline character
	if(type != PGTokenizerNewline) {
		[super append:text];
	}
	// parse
	BOOL success = YES;
	switch(_state) {
		case 0: // start of line state
			success =  [self _parse0:type text:text];
			break;
		case 1: // hash state
			success = [self _parse1:type text:text];
			break;
		case 2: // keyword state
			success = [self _parse2:type text:text];
			break;
		case 3: // value state
			success = [self _parse3:type text:text];
			break;
		case 4: // comment state
			success = [self _parse4:type text:text];
			break;
		case 5: // value suffix state
			success = [self _parse5:type text:text];
			break;
		default:
			success = NO;
			break;
	}
#ifdef DEBUG
	if(success==NO) {		
		NSLog(@"Error occurred: at {type %d, '%s'}, {state %ld}",type,text,_state);
	}
#endif
	return success;
}

-(NSString* )description {
	// return a non-parsed line
	if(_key && _value) {
		// return a parsed line
		return [NSString stringWithFormat:@"%@%@=%@ %@%@",
				(_enabled ? @"" : @"#"),
				_key,
				_value,
				([_comment length] ? @"#" : @""),
				([_comment length] ? _comment : @"")];
	} else {
		return [super description];
	}
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark PGServerConfiguration
////////////////////////////////////////////////////////////////////////////////

@implementation PGServerConfiguration

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithPath:(NSString* )path {
	self = [super initWithPath:path];
	if(self) {
		_keys = [NSMutableArray array];
		_index = [NSMutableDictionary dictionary];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// line factory

-(PGTokenizerLine* )lineFactory {
	return [[PGServerConfigurationKeyValue alloc] init];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

// keys we don't want user to be able to change these values!
-(NSArray* )_ignoreKeys {
	return [NSArray arrayWithObjects:@"data_directory",@"hba_file",@"ident_file",nil];
}

// return line for key
-(PGServerConfigurationKeyValue* )_lineForKey:(NSString* )key {
	return [_index objectForKey:key];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)load {
	[_keys removeAllObjects];
	[_index removeAllObjects];
	return [super load];
}

-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert([line isKindOfClass:[PGServerConfigurationKeyValue class]]);
	
	// append the line
	if([super append:line]==NO) {
		return NO;
	}
	
	PGServerConfigurationKeyValue* pair = (PGServerConfigurationKeyValue* )line;
	// only index key/value pair if there is both a key and value
	if([pair key]==nil) {
		return YES;
	}
	
	if([_keys containsObject:[pair key]]) {
#ifdef DEBUG
		NSLog(@"append: error, key exists: %@",[pair key]);
#endif
		return NO;
	}
	if([pair key] && [pair value] && [[self _ignoreKeys] containsObject:[pair key]]==NO) {
		[_keys addObject:[pair key]];
		[_index setValue:pair forKey:[pair key]];
	}
	return YES;
}

/*
-(BOOL)save {
	NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self path]];
	if(fileHandle==nil) {
#ifdef DEBUG
		NSLog(@"save: failed to open file: %@",[self path]);
#endif
		return NO;
	}
	
	// remove existing contents of the file
	[fileHandle truncateFileAtOffset:0];
	
	NSData* newLine = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
	for(PGServerConfigurationLine* line in _lines) {
		NSData* theData = [[line description] dataUsingEncoding:NSUTF8StringEncoding];
		[fileHandle writeData:theData];
		[fileHandle writeData:newLine];
	}
	[fileHandle closeFile];
	return YES;
}
*/

/*-(void)setValue:(NSObject* )value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error {
 
 }*/

-(PGTokenizerValue* )valueForKey:(NSString* )key {
	return [[self _lineForKey:key] value];
}

-(NSString* )stringForKey:(NSString* )key {
	return [[self valueForKey:key] stringValue];
}

-(BOOL)enabledForKey:(NSString* )key {
	return [[self _lineForKey:key] enabled];
}

-(NSString* )commentForKey:(NSString* )key {
	return [[self _lineForKey:key] comment];
}

@end
