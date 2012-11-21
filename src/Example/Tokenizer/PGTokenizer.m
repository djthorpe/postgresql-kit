
#import "PGTokenizer.h"


////////////////////////////////////////////////////////////////////////////////
// forward declaration, from PGTokenizer.lm

BOOL file_tokenize(PGTokenizer* tokenizer,const char* file);

////////////////////////////////////////////////////////////////////////////////

@implementation PGTokenizerLine

-(BOOL)parse:(PGTokenizerType)type text:(const char* )text {
	NSLog(@"parse: %d => %s",type,text);
	return YES;
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
		if([self load]==NO) {
			self = nil;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic path;

-(NSString* )path {
	return _path;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(PGTokenizerLine* )line {
	return [[PGTokenizerLine alloc] init];
}

-(BOOL)append:(PGTokenizerLine* )line {
	NSParameterAssert(line);
	[_lines addObject:line];
	return YES;
}

-(BOOL)load {
	[_lines removeAllObjects];
	_modified = NO;
	return file_tokenize(self,[[self path] UTF8String]);
}

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

@end

