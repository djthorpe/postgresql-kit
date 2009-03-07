
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

NSTimeInterval PostgresServerAppBackupTimerInterval = 5 * 60.0; // Backup fires once every five minutes
NSInteger PostgresServerAppBackupPercent = 50; // purges disk for backup when free space reaches this

@implementation PostgresServerApp

@synthesize server;
@synthesize connection;
@synthesize dataPath;
@synthesize backupPath;
@synthesize backupFreeSpacePercent;
@synthesize lastBackupTime;
@synthesize isRemoteAccess;
@synthesize isBackupEnabled;
@synthesize backupTimeInterval;
@synthesize serverPort;
@synthesize defaultServerPort;
@synthesize backupTimer;


////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_loadSettingsFromUserDefaults {
	// TODO: Load from system settings
	/*
	NSUserDefaults* theDefaults = [NSUserDefaults standardUserDefaults];
	if(theDefaults==nil) {
		[self serverMessage:@"Unable to load user defaults object"];
		return;
	}
	[self setIsBackupEnabled:[theDefaults boolForKey:@"isBackupEnabled"]];
	[self setBackupTimeInterval:[theDefaults floatForKey:@"backupTimeInterval"]];
	[self setBackupFreeSpacePercent:[theDefaults integerForKey:@"backupFreeSpacePercent"]];
	[self setIsRemoteAccess:[theDefaults boolForKey:@"isRemoteAccess"]];
	[self setServerPort:[theDefaults integerForKey:@"serverPort"]];
	 */
}

-(void)_saveSettingsToUserDefaults {
	// TODO: Save to system settings
	/*
	NSUserDefaults* theDefaults = [NSUserDefaults standardUserDefaults];
	if(theDefaults==nil) {
		[self serverMessage:@"Unable to load user defaults object"];
		return;
	}
	[theDefaults setBool:[self isBackupEnabled] forKey:@"isBackupEnabled"];
	[theDefaults setFloat:[self backupTimeInterval] forKey:@"backupTimeInterval"];
	[theDefaults setInteger:[self backupFreeSpacePercent] forKey:@"backupFreeSpacePercent"];
	[theDefaults setBool:[self isRemoteAccess] forKey:@"isRemoteAccess"];
	[theDefaults setInteger:[self serverPort] forKey:@"serverPort"];
	[theDefaults synchronize]; 
	 */
}

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	// save user defaults here
	[self _saveSettingsToUserDefaults];
	// release objects
	[self setDataPath:nil];
	[self setBackupPath:nil];
	[self setLastBackupTime:nil];
	[self setConnection:nil];
	[self setServer:nil];
	[[self backupTimer] invalidate];
	[self setBackupTimer:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)awakeThread {

	// set up shared postgres object
	[self setServer:[FLXServer sharedServer]];
	if([self server]==nil) {
		return NO;
	}
	
	// set postgres delegate
	[[self server] setDelegate:self];

	// NSConnection object
	[self setConnection:[NSConnection defaultConnection]];
	[[self connection] setRootObject:self];
	if([[self connection] registerName:PostgresServerAppIdentifier]==NO) {
		return NO;
	}

	// set server port to default
	defaultServerPort = [FLXServer defaultPort];	
	[self setServerPort:defaultServerPort];
	
	// set default percent
	[self setBackupFreeSpacePercent:PostgresServerAppBackupPercent];
	
	// retrieve settings from defaults file
	[self _loadSettingsFromUserDefaults];
	
	// success
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// messages

-(void)startServer {
	// set server info
	if([self isRemoteAccess]) {
		[[self server] setHostname:@"*"];
		[[self server] setPort:[self serverPort]];
		[self serverMessage:[NSString stringWithFormat:@"Setting hostname as %@ and port as %d",[[self server] hostname],[[self server] port]]];
	} else {
		[[self server] setHostname:nil];
		[self serverMessage:@"Setting hostname as nil (no remote connections)"];
	}
		
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    
	
	// start backup timer
	[[self backupTimer] invalidate];
	[self setBackupTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresServerAppBackupTimerInterval target:self selector:@selector(backupTimerDidFire:) userInfo:nil repeats:YES]];		
}

-(void)stopServer {
	// stop backup timer
	[[self backupTimer] invalidate];
	[self setBackupTimer:nil];	
	// stop server
	[[self server] stop];
}

-(NSString* )serverVersion {
	NSString* serverVersion = [[[self server] serverVersion] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString* serverPrefix = @"postgres (PostgreSQL) ";
	if([serverVersion hasPrefix:serverPrefix]) {
		return [serverVersion substringFromIndex:[serverPrefix length]];
	} else {
		return serverVersion;
	}
}

-(FLXServerState)serverState {
	return [[self server] state];
}

-(NSString* )serverStateAsString {
	return [[self server] stateAsString];
}

-(void)fireBackupCycle {
	if([self isBackupEnabled]) {
		[[self backupTimer] fire];
	}
}

////////////////////////////////////////////////////////////////////////////////

-(NSString* )dataSpaceFreeAsString {
	NSParameterAssert([self dataPath]);
	NSDictionary* theDictionary = [[NSFileManager defaultManager] fileSystemAttributesAtPath:[self dataPath]];
	if(theDictionary==nil) return nil;
	unsigned long long theFreeBytes = [[theDictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];		
	if(theFreeBytes >= (1024L * 1024L * 1024L)) {
		return [NSString stringWithFormat:@"%.2fGB",(double)theFreeBytes / (double)(1024L * 1024L * 1024L)];
	}
	if(theFreeBytes >= (1024L * 1024L)) {
		return [NSString stringWithFormat:@"%.2fMB",(double)theFreeBytes / (double)(1024L * 1024L)];
	}
	if(theFreeBytes >= 1024) {
		return [NSString stringWithFormat:@"%.2fKB",(double)theFreeBytes / (double)(1024L)];
	}
	return [NSString stringWithFormat:@"%llu bytes",theFreeBytes];
}

////////////////////////////////////////////////////////////////////////////////

-(void)backupTimerDidFire:(id)sender {
	// if backup not enabled, return
	if([self isBackupEnabled]==NO) return;
	// get directory for backups
	NSString* theDirectory = [[self backupPath] stringByAppendingPathComponent:@"backup"];
	// ensure is a directory, etc
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:theDirectory isDirectory:&isDirectory]==NO) {
		// we create the directory at the path
		NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0750],NSFilePosixPermissions,nil];
		BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:theDirectory attributes:theAttributes];
		if(isCreated==NO) {
			[self serverMessage:[NSString stringWithFormat:@"Unable to create directory at path: %@",theDirectory]];
			return;
		}
	}
	if(isDirectory==NO) {
		[self serverMessage:[NSString stringWithFormat:@"Not a directory at path: %@",theDirectory]];
		return;		
	}
	// get time interval for last backup time	
	NSTimeInterval theLastBackup = [self backupTimeInterval];
	if([self lastBackupTime]) {
		theLastBackup = [[NSDate date] timeIntervalSinceDate:[self lastBackupTime]];
	}	
	// don't read contents of directory to find the latest file if last time is under
	// half of the period
	if(theLastBackup < ([self backupTimeInterval] / 2.0)) {
		return;		
	}
	// mark the time it was done
	[self setLastBackupTime:[NSDate date]];
	// read directory for files
	NSDirectoryEnumerator* theEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:theDirectory];
	NSString* theFile = nil;
	NSDate* theLastFileDate = nil;
	NSString* theLastFileName = nil;
	while(theFile = [theEnumerator nextObject]) {
		// ignore hidden files
		if([theFile hasPrefix:@"."]) continue;
		// ignore non-files
		if([[theEnumerator fileAttributes] fileType] != NSFileTypeRegular) continue;
		// ignore files which do not have correct suffix
		if([theFile hasSuffix:[FLXServer backupFileSuffix]]==NO) continue;
		// get the creation date
		NSDate* theDate = [[theEnumerator fileAttributes] fileCreationDate];
		if(theDate==nil) {
			theDate = [[theEnumerator fileAttributes] fileModificationDate];
		}
		if(theDate==nil) {
			[self serverMessage:[NSString stringWithFormat:@"Unable to determine date on file: %@",theFile]];
			continue;
		}
		if(theLastFileDate==nil || [theLastFileDate isLessThan:theDate]) {
			theLastFileDate = theDate;
			theLastFileName = theFile;
		}
	}
	// no backup performed if backupTimeInterval not reached
	if(theLastFileDate !=nil && [[NSDate date] timeIntervalSinceDate:theLastFileDate] < [self backupTimeInterval]) {
		return;
	}
	// TODO: perform the free space purge, based on size of last backup file plus 10%
	// ...but don't remove the last backup
	// do {
		// estimated_backup_size = last_backup_size * 1.1
		// freespace_in_percent = (free_space - estimated_backup_size) * 100 / total_space
	// while(freespace_in_percent <= freespace_threshold)
	
	NSLog(@"TODO: purge backup directory %@",theDirectory);

	// write the file
	[self serverMessage:@"Initiating backup"];

	// perform backup in background
	[[self server] backupInBackgroundToFolderPath:theDirectory];
}

////////////////////////////////////////////////////////////////////////////////

-(void)serverMessage:(NSString* )theMessage {
	NSLog(@"server message: %@",theMessage);
}

-(void)serverStateDidChange:(NSString* )theMessage {
	NSLog(@"server state did change: %@",theMessage);	
}

-(void)backupStateDidChange:(NSString* )theMessage {
	NSLog(@"backup state did change: %@",theMessage);	
}

@end
