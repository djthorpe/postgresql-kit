
#import "PGServerKit.h"

@implementation PGServerPreferences
@dynamic modified;
@dynamic path;

////////////////////////////////////////////////////////////////////////////////
// init methods

-(id)init {
	return nil;
}

-(id)initWithConfigurationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in configuration file
		if([super load:path]==NO) {
			return nil;
		}
		_path = path;
	}
	return self;
}

-(id)initWithAuthenticationFile:(NSString* )path {
	self = [super init];
	if(self) {
		// read in authentication file		
		if([super load:path]==NO) {
			return nil;
		}
		_path = path;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(BOOL)modified {
	return [super modified];
}

-(NSString* )path {
	return _path;
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)save {
	if(_path==nil) {
#ifdef DEBUG
		NSLog(@"save: failed, no path");
#endif
		return NO;
	}
	if([[NSFileManager defaultManager] isWritableFileAtPath:_path]==NO) {
#ifdef DEBUG
		NSLog(@"save: failed, not writable: %@",_path);
#endif
		return NO;
	}
	NSLog(@"saving %@",_path);
	BOOL isSuccess = [super save:_path];
	if(isSuccess==NO) {
		return NO;
	}
	// re-read file from filesystem, making it non-modified again
	if([super load:_path]==NO) {
#ifdef DEBUG
		NSLog(@"save: failed, post-save load failed: %@",_path);
#endif
		return NO;
	}
	// return YES
	return YES;
}

@end
