
#import "PGServer+Backup.h"
#import <zlib.h>

@implementation PGServer (Backup)

+(NSString* )_backupFileSuffix {
	return @"sql.gz";
}

// create a unique backup filename
-(NSString* )_backupFilePathForFolder:(NSString* )thePath {
	// ensure path is a directory
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO || isDirectory==NO) {
		return nil;
	}
	// initialize random seed
	srand((unsigned)time(NULL));
	NSInteger theRandomNumber = rand() % 10000L;
	// construct filename
	NSCalendarDate* theDate = [NSCalendarDate calendarDate];
	NSString* theFilename = [NSString stringWithFormat:@"pgdump-%@-%04ld.%@",[theDate descriptionWithCalendarFormat:@"%Y%m%d-%H%M%S"],theRandomNumber,[[self class] _backupFileSuffix]];
	NSString* theFilepath = [thePath stringByAppendingPathComponent:theFilename];
	// make sure file does not exist
	if([[NSFileManager defaultManager] fileExistsAtPath:theFilepath]==YES) {
		return nil;
	}
	// return filename
	return theFilepath;
}

// performs a backup of the local postgres database using the superuser account
// performs .gz compression on the file
// returns the path to the backup file
-(NSString* )backupToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword {
	NSParameterAssert(thePath);
    
	// construct file for writing
	NSString* theOutputFilePath = [self _backupFilePathForFolder:thePath];
	if(theOutputFilePath==nil) {
		return nil;
	}

	// create the file
	if([[NSFileManager defaultManager] createFileAtPath:theOutputFilePath contents:nil attributes:nil]==NO) {
		return nil;
	}

	// open the file for writing
	NSFileHandle* theOutputFile = [NSFileHandle fileHandleForWritingAtPath:theOutputFilePath];
	if(theOutputFile==nil) {
		return nil;
	}
    
	// create gzip file descriptor
	gzFile theCompressedOutputFile = gzdopen([theOutputFile fileDescriptor],"wb");
	NSParameterAssert(theCompressedOutputFile);
	
	// setup the task
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSPipe* theErrPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theErrPipe];
	[theTask setLaunchPath:[[self class] postgresDumpPath]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-p",[NSString stringWithFormat:@"%u",[self port]],@"-U",[[self class] superUsername],@"-S",[[self class] superUsername],@"--disable-triggers",nil]];
	
	if([thePassword length]) {
		// set the PGPASSWORD env variable
		[theTask setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:thePassword,@"PGPASSWORD",[[self class] postgresLibPath],@"DYLD_LIBRARY_PATH",nil]];
	} else {
		[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] postgresLibPath] forKey:@"DYLD_LIBRARY_PATH"]];
	}
	
	// perform the backup
	[theTask launch];
	
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		NSInteger bytesWritten = gzwrite(theCompressedOutputFile,[theData bytes],[theData length]);
		NSParameterAssert(bytesWritten);
	}
    
	// close the compressed stream
	gzclose(theCompressedOutputFile);
	
	// get error information....
	while((theData = [[theErrPipe fileHandleForReading] availableData]) && [theData length]) {
		[self _delegateServerMessageFromData:theData];
	}
	
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];
	[theTask release];
	[theOutPipe release];
	[theErrPipe release];
	[theOutputFile closeFile];
	
	if(theReturnCode==0) {
		return theOutputFilePath;
	} else {
		[[NSFileManager defaultManager] removeItemAtPath:theOutputFilePath error:nil];
		return nil;
	}	
}

@end
