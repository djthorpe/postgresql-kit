
#import "PostgresServerKit.h"
#import "PostgresServerKitPrivate.h"

@implementation FLXPostgresServer (Access)

+(NSString* )postgresAccessPathForDataPath:(NSString* )thePath {
	return [thePath stringByAppendingPathComponent:@"pg_hba.conf"];
}

+(NSString* )postgresIdentityPathForDataPath:(NSString* )thePath {
	return [thePath stringByAppendingPathComponent:@"pg_ident.conf"];
}

-(NSArray* )readAccessTuples {
	// this will only work if the server is started
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Cannot read access file without server running"];
		return nil;
	}
	NSError* theError = nil;
	NSString* thePath = [FLXPostgresServer postgresAccessPathForDataPath:[self dataPath]];
	NSString* theContents = [NSString stringWithContentsOfFile:thePath encoding:NSUTF8StringEncoding error:&theError];
	if(theContents==nil) {
		[self _delegateServerMessage:[NSString stringWithFormat:@"File not readable: %@: %@",thePath,[theError localizedDescription]]];
		return nil;
	}
	NSArray* theLines = [theContents componentsSeparatedByString:@"\n"];

	// parse lines into tuples	
	NSMutableArray* theTuples = [[NSMutableArray alloc] initWithCapacity:[theLines count]];
	NSString* theComment = nil;
	NSUInteger theLineNumber = 0;
	BOOL isSuperAdminAccessTuple = NO;
	for(NSString* theLine in theLines) {
		theLineNumber++;
		NSString* theLine2 = [theLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([theLine2 length]==0) {
			theComment = nil;
			continue;
		}
		if([theLine2 hasPrefix:@"#"]) {
			theComment = [[theLine2 stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			continue;
		}
		FLXPostgresServerAccessTuple* theTuple = [[FLXPostgresServerAccessTuple alloc] initWithLine:theLine2];
		if(theTuple==nil) {
			// error parsing line
			[self _delegateServerMessage:[NSString stringWithFormat:@"Parse error: %@: line %u",thePath,theLineNumber]];
			return nil;
		}
		// check for superadmin access tuple
		if(isSuperAdminAccessTuple==NO && [theTuple isSuperadminAccess]==YES) {
			isSuperAdminAccessTuple = YES;
		}
		// add comment to tuple
		[theTuple setComment:theComment];
		// add tuple
		[theTuples addObject:theTuple];
		// empty comment
		theComment = nil;
	}
	
	// append superadmin access tuple if necessary
	if(isSuperAdminAccessTuple==NO) {
		[theTuples insertObject:[FLXPostgresServerAccessTuple superadmin] atIndex:0];
	}
	
	return theTuples;
}

-(BOOL)writeAccessTuples:(NSArray* )theTuples {
	NSParameterAssert(theTuples);
	NSParameterAssert([theTuples count]);

	// this will only work if the server is started
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Cannot write access file without server running"];
		return NO;
	}
	NSString* thePath = [FLXPostgresServer postgresAccessPathForDataPath:[self dataPath]];
	NSMutableString* theContents = [NSMutableString string];
	for(FLXPostgresServerAccessTuple* theTuple in theTuples) {
		NSParameterAssert(theTuple);
		[theContents appendString:[theTuple asString]];
	}
	
	NSError* theError = nil;
	if([theContents writeToFile:thePath atomically:NO encoding:NSUTF8StringEncoding error:&theError]==NO) {
		[self _delegateServerMessage:[NSString stringWithFormat:@"File not writable: %@: %@",thePath,[theError localizedDescription]]];
		return NO;	
	}
	
	return YES;
}

-(NSArray* )readIdentityTuples {
	// this will only work if the server is started
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Cannot read access file without server running"];
		return nil;
	}
	NSError* theError = nil;
	NSString* thePath = [FLXPostgresServer postgresIdentityPathForDataPath:[self dataPath]];
	NSString* theContents = [NSString stringWithContentsOfFile:thePath encoding:NSUTF8StringEncoding error:&theError];
	if(theContents==nil) {
		[self _delegateServerMessage:[NSString stringWithFormat:@"File not readable: %@: %@",thePath,[theError localizedDescription]]];
		return nil;
	}
	NSArray* theLines = [theContents componentsSeparatedByString:@"\n"];
	
	// parse lines into tuples	
	NSMutableArray* theTuples = [[NSMutableArray alloc] initWithCapacity:[theLines count]];
	NSUInteger theLineNumber = 0;
	for(NSString* theLine in theLines) {
		theLineNumber++;
		NSString* theLine2 = [theLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([theLine2 length]==0) {
			continue;
		}
		if([theLine2 hasPrefix:@"#"]) {
			continue;
		}
		FLXPostgresServerIdentityTuple* theTuple = [[FLXPostgresServerIdentityTuple alloc] initWithLine:theLine2];
		if(theTuple==nil) {
			// error parsing line
			[self _delegateServerMessage:[NSString stringWithFormat:@"Parse error: %@: line %u",thePath,theLineNumber]];
			return nil;
		}
		// add tuple
		[theTuples addObject:theTuple];
	}
	
	return theTuples;
}


@end
