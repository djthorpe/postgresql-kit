
#import "PGServerConfigurationLine.h"

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerConfigurationValue

-(id)initWithType:(PGServerConfigurationValueType)type value:(const char* )value {
    self = [super init];
    if (self) {
		_type = type;
		_value = [NSString stringWithUTF8String:value];
    }
    return self;
}

+(PGServerConfigurationValue* )valueWithSQString:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeSQString value:value];
}

+(PGServerConfigurationValue* )valueWithDQString:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeDQString value:value];
}

+(PGServerConfigurationValue* )valueWithKeyword:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeKeyword value:value];
}

+(PGServerConfigurationValue* )valueWithInteger:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeInteger value:value];
}

+(PGServerConfigurationValue* )valueWithFloat:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeFloat value:value];
}

+(PGServerConfigurationValue* )valueWithBool:(const char* )value {
	return [[PGServerConfigurationValue alloc] initWithType:PGTypeBool value:value];
}


-(NSString* )typeAsString {
	switch(_type) {
		case PGTypeSQString:
			return @"PGTypeSQString";
		case PGTypeDQString:
			return @"PGTypeDQString";
		case PGTypeKeyword:
			return @"PGTypeKeyword";
		case PGTypeInteger:
			return @"PGTypeInteger";
		case PGTypeFloat:
			return @"PGTypeFloat";
		case PGTypeBool:
			return @"PGTypeBool";
		default:
			return nil;
	}
}

-(NSString* )description {
	if(_suffix) {
		return [NSString stringWithFormat:@"%@<%@ %@>",[self typeAsString],_value,_suffix];
	} else {
		return [NSString stringWithFormat:@"%@<%@>",[self typeAsString],_value];		
	}
}

@dynamic quotedValue;
@dynamic value;

-(NSString* )quotedValue {
	if(_suffix) {
		return [NSString stringWithFormat:@"%@%@",_value,_suffix];
	} else {
		return _value;
	}
}

-(NSObject* )value {
	switch(_type) {
		case PGTypeSQString:
			// TODO: return NSString without single quotes
		case PGTypeDQString:
			// TODO: return NSString without double quotes
		case PGTypeKeyword:
			return _value;
		case PGTypeInteger:
			// TODO: what to do about the suffix
			return [NSNumber numberWithInteger:[_value integerValue]];
		case PGTypeFloat:
			// TODO: what to do about the suffix
			return [NSNumber numberWithDouble:[_value doubleValue]];
		case PGTypeBool:
			if([_value isEqualToString:@"on"]) {
				return [NSNumber numberWithBool:YES];
			} else if([_value isEqualToString:@"off"]) {
				return [NSNumber numberWithBool:NO];
			}
	}
	return nil;
}

-(void)setValue:(NSObject* )value {
	// TODO
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerConfigurationLine

-(id)init {
    self = [super init];
    if (self) {
		_state = 0;
		_enabled = NO;
		_line = [NSMutableString string];
		_comment = [NSMutableString string];
		_key = nil;
		_value = nil;
    }
    return self;
}

-(BOOL)_parse0:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerHash:
			_enabled = NO;
			_state = 1;
			return YES;
		case PGTokenizerKeyword:
			_enabled = YES;
			_key = [NSString stringWithUTF8String:text];
			_state = 2;
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		case PGTokenizerNewline:
			_eject = YES;
			return YES;
		default:
			return NO;
	}
}

-(BOOL)_parse1:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			_key = [NSString stringWithUTF8String:text];
			_state = 2;
			return YES;
		case PGTokenizerNewline:
			_eject = YES;
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
			_eject = YES;
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
			_value = [PGServerConfigurationValue valueWithSQString:text];
			return YES;
		case PGTokenizerDQString:
			_value = [PGServerConfigurationValue valueWithDQString:text];
			return YES;
		case PGTokenizerInteger:
			_value = [PGServerConfigurationValue valueWithInteger:text];
			_state = 5;
			return YES;
		case PGTokenizerFloat:
			_value = [PGServerConfigurationValue valueWithFloat:text];
			return YES;
		case PGTokenizerKeyword:
			if(strcasecmp(text,"on")==0 || strcasecmp(text,"off")==0) {
				_value = [PGServerConfigurationValue valueWithBool:text];
			} else {
				_value = [PGServerConfigurationValue valueWithKeyword:text];
			}
			return YES;
		case PGTokenizerHash:
			_state = 4;
			return YES;
		case PGTokenizerNewline:
			_eject = YES;
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
			_eject = YES;
			return YES;
		default:
			[_comment appendString:[NSString stringWithUTF8String:text]];
			return YES;
	}
}

-(BOOL)_parse5:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			[_value setSuffix:[NSString stringWithUTF8String:text]];
			return YES;
		case PGTokenizerHash:
			_state = 4;
			return YES;
		case PGTokenizerNewline:
			_eject = YES;
			return YES;
		case PGTokenizerWhitespace:
			return YES;
		default:
			return NO;
	}
}

-(BOOL)_parse:(PGTokenizerType)type text:(const char* )text {

	// append to _line if not newline character
	if(type != PGTokenizerNewline) {
		[_line appendString:[NSString stringWithUTF8String:text]];
	}
	
	// parse
	switch(_state) {
		case 0: // start of line state
			return [self _parse0:type text:text];
		case 1: // hash state
			return [self _parse1:type text:text];
		case 2: // keyword state
			return [self _parse2:type text:text];
		case 3: // value state
			return [self _parse3:type text:text];
		case 4: // comment state
			return [self _parse4:type text:text];
		case 5: // value suffix state
			return [self _parse5:type text:text];
		default:
			return NO;
	}
}

-(NSString* )description {
	// return a non-parsed line
	if(_key && _value) {
		// return a parsed line
		return [NSString stringWithFormat:@"%@%@=%@ %@%@",
				(_enabled ? @"" : @"#"),
				_key,
				[_value quotedValue],
				([_comment length] ? @"#" : @""),
				([_comment length] ? _comment : @"")];
	} else {
		return [NSString stringWithFormat:@"%@",_line];
	}
}

@end
