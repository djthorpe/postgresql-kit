
#import "PGTokenizerLine.h"

@implementation PGTokenizerLine

@dynamic keyword;
@dynamic value;
@dynamic comment;
@dynamic enabled;

-(id)init {
	self = [super init];
	if(self) {
		_state = 0;
		_text = [[NSMutableString alloc] init];
		_enabled = NO;
		_keyword = nil;
		_value = [[NSMutableString alloc] init];
		_comment = [[NSMutableString alloc] init];
	}
	return self;
}

-(void)_state0:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerHash:
			// start of comment, switch to state 1
			_enabled = NO;
			_state = 1;
			return;
		case PGTokenizerKeyword:
			// keyword, switch to state 2
			_enabled = YES;
			_keyword = [NSString stringWithUTF8String:text];
			_state = 2;
			return;
		default:
			// other states, ignore
			_state = 99;
			return;
	}
}

-(void)_state1:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerKeyword:
			// keyword, switch to state 2
			_keyword = [NSString stringWithUTF8String:text];
			_state = 2;
			return;
		default:
			// other states, ignore
			_state = 99;
			return;
	}
}

-(void)_state2:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerWhitespace:
			// ignore
			return;
		case PGTokenizerEquals:
			// keyword, switch to state 3
			_state = 3;
			return;
		default:
			// other states, ignore
			_state = 99;
			return;
	}
}

-(void)_state3:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		case PGTokenizerHash:
			// switch to comment state
			_state = 4;
			return;
		case PGTokenizerWhitespace:
			// ignore
			return;
		default:
			[_value appendString:[NSString stringWithUTF8String:text]];
			return;
	}
}

-(void)_state4:(PGTokenizerType)type text:(const char* )text {
	switch(type) {
		default:
			[_comment appendString:[NSString stringWithUTF8String:text]];
			return;
	}
}

-(void)token:(PGTokenizerType)type text:(const char* )text {
	[_text appendString:[NSString stringWithUTF8String:text]];
	switch(_state) {
		case 0: // start of line state
			[self _state0:type text:text];
			return;
		case 1: // start of comment state
			[self _state1:type text:text];
			return;
		case 2: // start of keyword state
			[self _state2:type text:text];
			return;
		case 3:
			[self _state3:type text:text];
			return;
		case 4:
			[self _state4:type text:text];
			return;
		case 99:
			// remove keyword - aborted parse
			_keyword = nil;
		default:
			// ignore remaining text
			return;
	}
}

-(NSString* )keyword {
	return _keyword;
}

-(NSString* )comment {
	if(_keyword) {
		return _comment;
	} else {
		return nil;
	}
}

-(NSString* )value {
	if(_keyword) {
		return _value;
	} else {
		return nil;
	}
}

-(void)setValue:(NSString* )theValue {
	_value = [theValue mutableCopy];
}

-(void)setEnabled:(BOOL)theValue {
	_enabled = theValue;
}

-(BOOL)enabled {
	if(_keyword) {
		return _enabled;
	} else {
		return NO;
	}
}

-(NSString* )description {
	if(_keyword==nil) {
		return [NSString stringWithFormat:@"%@",_text];
	} else {
		return [NSString stringWithFormat:@"<enabled: %@ keyword<%@> value<%@> comment<%@>>",
				(_enabled ? @"YES" : @"NO"),_keyword,_value,_comment];
	}
}

@end
