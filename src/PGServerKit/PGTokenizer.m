
#import "PGTokenizer.h"

////////////////////////////////////////////////////////////////////////////////
// forward declaration, from PGTokenizer.lm

BOOL file_tokenize(PGTokenizer* tokenizer,const char* file);

////////////////////////////////////////////////////////////////////////////////

@implementation PGTokenizerValue

-(id)init {
	return nil;
}

-(id)initWithText:(const char* )text type:(PGTokenizerType)type {
	self = [super init];
	if(self) {
		_type = type;
		_text = [NSString stringWithUTF8String:text];
	}
	return self;
}

+(PGTokenizerValue* )valueWithText:(const char* )text type:(PGTokenizerType)type {
	return [[PGTokenizerValue alloc] initWithText:text type:type];
}

-(NSString* )stringValue {
	NSMutableString* value = [_text mutableCopy];
	if(_type==PGTokenizerSQString) {
		NSParameterAssert([_text hasPrefix:@"\'"] && [_text hasSuffix:@"\'"]);
		[value replaceCharactersInRange:NSMakeRange(0,1) withString:@""];
		[value replaceCharactersInRange:NSMakeRange([value length]-1,1) withString:@""];
		[value replaceOccurrencesOfString:@"\\\'" withString:@"\'" options:0 range:NSMakeRange(0,[value length])];
		[value replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0,[value length])];
		return value;
	} else if(_type==PGTokenizerDQString) {
		NSParameterAssert([_text hasPrefix:@"\""] && [_text hasSuffix:@"\""]);
		[value replaceCharactersInRange:NSMakeRange(0,1) withString:@""];
		[value replaceCharactersInRange:NSMakeRange([value length]-1,1) withString:@""];
		[value replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:NSMakeRange(0,[value length])];
		[value replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0,[value length])];
		return value;
	} else {
		return _text;
	}
}

+(NSString* )_stringForType:(PGTokenizerType)type {
	switch(type) {
		case PGTokenizerSQString:
			return @"PGTokenizerSQString";
		case PGTokenizerDQString:
			return @"PGTokenizerDQString";
		case PGTokenizerOctal:
			return @"PGTokenizerOctal";
		case PGTokenizerDecimal:
			return @"PGTokenizerDecimal";
		case PGTokenizerFloat:
			return @"PGTokenizerFloat";
		case PGTokenizerKeyword:
			return @"PGTokenizerKeyword";
		case PGTokenizerIP4Addr:
			return @"PGTokenizerIP4Addr";
		case PGTokenizerIPMask:
			return @"PGTokenizerIPMask";
		case PGTokenizerIP6Addr:
			return @"PGTokenizerIP6Addr";
		case PGTokenizerHostname:
			return @"PGTokenizerHostname";
		case PGTokenizerGroupMap:
			return @"PGTokenizerGroupMap";
		default:
			return @"PGTokenizerOther";
	}
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<PGTokenizerValue type=%@ text=%@>",[PGTokenizerValue _stringForType:_type],_text];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGTokenizerLine

-(id)init {
	self = [super init];
	if(self) {
		_text = [[NSMutableString alloc] init];
	}
	return self;
}

-(void)append:(const char* )text {
	[_text appendString:[NSString stringWithUTF8String:text]];
}

-(BOOL)parse:(PGTokenizerType)type text:(const char* )text {	
	switch(type) {
		case PGTokenizerNewline:
			[self setEject:YES];
			return YES;
		default:
			[self append:text];
			return YES;
	}
}

-(NSString* )description {
	return _text;
}

@end

@implementation PGTokenizer

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path {
	self = [super init];
	if(self) {
		_path = path;
		_lines = [NSMutableArray array];
		_modified = NO;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

// return a new line
-(PGTokenizerLine* )lineFactory {
	return [[PGTokenizerLine alloc] init];
}

// append a line
-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert(line);
	[_lines addObject:line];
	_modified = YES;
	return YES;
}

// remove a line
-(BOOL)remove:(PGTokenizerLine* )line {
	NSParameterAssert(line);
	if([_lines containsObject:line]==NO) {
		return NO;
	}
	[_lines removeObject:line];
	_modified = YES;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic path;

-(NSString* )path {
	return _path;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

// load the file
-(BOOL)load {
	[_lines removeAllObjects];
	BOOL success = file_tokenize(self,[[self path] UTF8String]);
	_modified = NO;
	return success;
}

// save the file
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
	for(PGTokenizerLine* line in _lines) {
		NSData* theData = [[line description] dataUsingEncoding:NSUTF8StringEncoding];
		[fileHandle writeData:theData];
		[fileHandle writeData:newLine];
	}
	[fileHandle closeFile];
	_modified = NO;
	return YES;
}

-(NSString* )description {
	return [_lines componentsJoinedByString:@"\n"];
}

@end

