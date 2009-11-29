
#import "PostgresServerKit.h"

@implementation FLXPostgresServer (Access)

+(NSString* )postgresAccessPathForDataPath:(NSString* )thePath {
	return [thePath stringByAppendingPathComponent:@"data/pg_hba.conf"];
}

-(NSArray* )readAccessTuples {
	// this will only work if the server is started
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		return nil;
	}
	NSString* thePath = [FLXPostgresServer postgresAccessPathForDataPath:[self dataPath]];
	if([[NSFileManager defaultManager] isReadableFileAtPath:thePath]==NO) {
		return nil;
	}
	NSString* theContents = [NSString stringWithContentsOfFile:thePath encoding:NSUTF8StringEncoding error:nil];							 
	if(theContents==nil) {
		return nil;
	}
	NSArray* theLines = [theContents componentsSeparatedByString:@"\n"];
	return theLines;
}

-(BOOL)writeAccessTuples:(NSArray* )theTuples {
	NSParameterAssert(theTuples);
	
	return YES;
}

@end
