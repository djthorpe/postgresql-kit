
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import <PostgresDataKit/PostgresDataKit.h>
#import "Name.h"

BOOL readAccessFile() {
	NSString* thePath = @"/Users/djt/pg_hba.conf";
	if([[NSFileManager defaultManager] isReadableFileAtPath:thePath]==NO) {
		return NO;
	}
	NSString* theContents = [NSString stringWithContentsOfFile:thePath];
	if(theContents==nil) {
		return NO;
	}
	NSScanner* theScanner = [NSScanner scannerWithString:theContents];
	[theScanner setCharactersToBeSkipped:nil];
	NSCharacterSet* newlineCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
	NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	NSString* theString = nil;	
	while([theScanner isAtEnd]==NO) {
		if([theScanner scanString:@"#" intoString:nil]==YES) {
			if([theScanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&theString]==YES) {
				NSLog(@"comment = %@",theString);					
			} else {
				NSLog(@"comment = EMPTY");
			}
			[theScanner scanCharactersFromSet:newlineCharacterSet intoString:nil];
		} else if([theScanner scanCharactersFromSet:whitespaceCharacterSet intoString:nil]) {
			continue;
		} else if([theScanner scanCharactersFromSet:newlineCharacterSet intoString:nil]) {
			continue;			
		} else if([theScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&theString]) {
			[theScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
			NSLog(@"string1 = %@",theString);
		} else {
			return NO;
		}
	}
	return YES;
}



int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	readAccessFile();
	
	/*
	FLXPostgresConnection* connection = [[FLXPostgresConnection alloc] init];

	[connection setUser:@"postgres"];
	[connection setDatabase:@"postgres"];
	
	@try {
		FLXPostgresDataCache* theCache = [FLXPostgresDataCache sharedCache];
		// set data cache connection, and connect
		[theCache setConnection:connection];
		[connection connect];

		// create 'name' table		
		NSArray* theTables = [connection tablesInSchema:@"public"];
		if([theTables containsObject:@"name"]) {
			[connection execute:@"DROP TABLE name"];
		}
		
		// create table
		[connection execute:@"CREATE TABLE name (id INTEGER PRIMARY KEY,name VARCHAR(80),email VARCHAR(80))"];
		

		// create a new name object
		Name* theName = [theCache newObjectForClass:[Name class]];
		
		[theName setValue:@"David Thorpe" forKey:@"name"];
		
		// commit changes to database
		//[theCache commit];		
		
		NSLog(@"name = %@",theName);
		
		// unset connection
		[theCache setConnection:nil];		
		
	} @catch(NSException* theException) {
		NSLog(@"Error: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[connection release];
	 
	 */
	
	
	
	
	[pool release];
	return 0;
}
