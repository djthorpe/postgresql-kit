
#import "PGTokenizer.h"
#import "PGTokenizerLine.h"

// forward declarations
BOOL file_tokenize(PGTokenizer* tokenizer,const char* file);

@interface PGTokenizerLine (Private)
-(void)token:(PGTokenizerType)type text:(const char* )text;
@end

// implementation of PGTokenizer class
@implementation PGTokenizer
@dynamic modified;
@dynamic count;

-(id)init {
	self = [super init];
	if(self) {
		_lines = [[NSMutableArray alloc] init];
		_index = [[NSMutableDictionary alloc] init];
		_keywords = [[NSMutableArray alloc] init];
		_modified = NO;
	}
	return self;
}

-(BOOL)modified {
	return _modified;
}

-(NSInteger)count {
	return [_keywords count];
}

-(NSString* )keyAtIndex:(NSInteger)rowIndex {
	NSParameterAssert(rowIndex >= 0);
	NSParameterAssert(rowIndex < [_keywords count]);
	return [_keywords objectAtIndex:rowIndex];
}

-(BOOL)enabledForKey:(NSString* )theKey {
	NSParameterAssert(theKey);
	PGTokenizerLine* theLine = [_index objectForKey:theKey];
	NSParameterAssert(theLine);
	return [theLine enabled];
}

-(NSString* )commentForKey:(NSString* )theKey {
	NSParameterAssert(theKey);
	PGTokenizerLine* theLine = [_index objectForKey:theKey];
	NSParameterAssert(theLine);
	return [theLine comment];
}

-(NSString* )valueForKey:(NSString* )theKey {
	NSParameterAssert(theKey);
	PGTokenizerLine* theLine = [_index objectForKey:theKey];
	if(theLine==nil) {
		return nil;
	}
	return [theLine value];
}

-(void)setValue:(NSString* )theValue forKey:(NSString* )theKey {
	NSParameterAssert(theValue && theKey);
	PGTokenizerLine* theLine = [_index objectForKey:theKey];
	NSParameterAssert(theLine);
	[theLine setValue:theValue];
	_modified = YES;
}

-(void)setEnabled:(BOOL)theValue forKey:(NSString* )theKey {
	NSParameterAssert(theKey);
	PGTokenizerLine* theLine = [_index objectForKey:theKey];
	NSParameterAssert(theLine);
	[theLine setEnabled:theValue];
	_modified = YES;
}

-(BOOL)shouldIndex:(PGTokenizerLine* )theLine {
	return YES;
}

-(BOOL)load:(NSString* )thePath {
	// empty the structures
	[_lines removeAllObjects];
	[_keywords removeAllObjects];
	[_index removeAllObjects];
	_modified = NO;
	
	// tokenize the file
	BOOL isSuccess = file_tokenize(self,[thePath UTF8String]);
	if(!isSuccess) {
		return NO;
	}
	// index all the keyword=value lines
	for(PGTokenizerLine* line in _lines) {
		if([self shouldIndex:line] && [line keyword]) {
			[_index setObject:line forKey:[line keyword]];
			[_keywords addObject:[line keyword]];
		}
	}
	// set modified as NO
	_modified = NO;
	// return success
	return YES;
}

-(BOOL)save:(NSString* )thePath {
	NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:thePath];
	if(fileHandle==nil) {
#ifdef DEBUG
		NSLog(@"save: failed to open file: %@",thePath);
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

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)token:(PGTokenizerType)type text:(const char* )text {
	// create a new line if there are no lines
	if([_lines count]==0) {
		[_lines addObject:[[PGTokenizerLine alloc] init]];
	}
	PGTokenizerLine* line = [_lines lastObject];
	NSParameterAssert(line);
	
	if(type==PGTokenizerNewline) {
		// eject the current line by adding a new one
		[_lines addObject:[[PGTokenizerLine alloc] init]];
		return;
	}
	// append this token to the current line
	[line token:type text:text];
}

@end