
#import "PGTokenizer.h"

// forward declaration
BOOL file_tokenize(PGTokenizer* tokenizer,const char* file);

@implementation PGTokenizer

-(id)init {
	self = [super init];
	if(self) {
		_lines = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL)parse:(NSString* )thePath {
	// empty the _line structure
	[_lines removeAllObjects];
	// tokenize the file
	return file_tokenize(self,[thePath UTF8String]);
}

-(void)token:(PGTokenizerType)type text:(const char* )text {
	// create a new line if there are no lines
	if([_lines count]==0) {
		[_lines addObject:[[PGTokenizerLine alloc] init]];
	}
	PGTokenizerLine* line = [_lines lastObject];
	NSParameterAssert(line);
	
	if(type==PGTokenizerNewline) {
		// eject the current line by adding a new one
#ifdef DEBUG
		NSLog(@"%@",line);
#endif
		[_lines addObject:[[PGTokenizerLine alloc] init]];
		return;
	}
	// append this token to the current line
	[line append:type text:text];
}

@end
