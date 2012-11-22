
#import "PGTokenizer.h"

////////////////////////////////////////////////////////////////////////////////
// forward declaration, from PGTokenizer.lm

BOOL file_tokenize(PGTokenizer* tokenizer,const char* file);

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
// private methods

// return a new line
-(PGTokenizerLine* )makeLine {
	return [[PGTokenizerLine alloc] init];
}

// append a line
-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert(line);
	[_lines addObject:line];
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
	_modified = NO;
	return file_tokenize(self,[[self path] UTF8String]);
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
	return YES;
}

-(NSString* )description {
	return [_lines componentsJoinedByString:@"\n"];
}

@end

