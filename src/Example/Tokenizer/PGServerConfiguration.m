
#import "PGServerConfiguration.h"

BOOL file_tokenize(PGServerConfiguration* tokenizer,const char* file);

@implementation PGServerConfiguration

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path {
	self = [super init];
	if(self) {
		_path = path;
		_lines = [NSMutableArray array];
		_keys = [NSMutableArray array];
		_index = [NSMutableDictionary dictionary];
		_modified = NO;
		if([self load]==NO) {
			self = nil;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic path;

-(NSString* )path {
	return _path;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

// keys we don't want user to be able to change
-(NSArray* )_ignoreKeys {
	return [NSArray arrayWithObjects:@"data_directory",@"hba_file",@"ident_file",nil];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)append:(PGServerConfigurationLine* )line {
	NSParameterAssert(line);
	[_lines addObject:line];

	// only index key/value pair if there is both a key and value
	NSString* key = [line key];
	if([_keys containsObject:key]) {
#ifdef DEBUG
		NSLog(@"append: error, key exists: %@",key);
#endif
		return NO;
	}
	if(key && [line value] && [[self _ignoreKeys] containsObject:key]==NO) {
		[_keys addObject:[line key]];
		[_index setValue:line forKey:key];
	}
	return YES;
}

-(BOOL)load {
	[_lines removeAllObjects];
	[_keys removeAllObjects];
	[_index removeAllObjects];
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
	for(PGServerConfigurationLine* line in _lines) {
		NSData* theData = [[line description] dataUsingEncoding:NSUTF8StringEncoding];
		[fileHandle writeData:theData];
		[fileHandle writeData:newLine];
	}
	[fileHandle closeFile];
	return YES;
}

-(NSObject* )valueForKey:(NSString* )key {
	PGServerConfigurationLine* line = [_index objectForKey:key];
	if(line==nil) {
		// value does not exist
		return nil;
	}
	PGServerConfigurationValue* value = [line value];
	NSParameterAssert(value);
	return [value description];
}

@end
