
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

NSTimeInterval PostgresServerAppBackupTimerInterval = 5 * 60.0; // Backup fires once every five minutes
NSInteger PostgresServerAppBackupPercent = 50; // purges disk for backup when free space reaches this

@implementation PostgresServerApp

@synthesize server;
@synthesize client;
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
@synthesize keychain;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_settingsPath {
	// return path to stored preferences
	return [[self dataPath] stringByAppendingPathComponent:@"preferences.plist"];
}

-(void)_loadSettingsFromUserDefaults {
	// Load from system settings
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _settingsPath]]==NO) {
		return;
	}
	NSDictionary* thePreferences = [NSDictionary dictionaryWithContentsOfFile:[self _settingsPath]];
	if(thePreferences==nil) {
		return;
	}
	for(NSString* theKey in [thePreferences allKeys]) {
		NSObject* theValue = [thePreferences objectForKey:theKey];
		if([theKey isEqual:@"isBackupEnabled"] && [theValue isKindOfClass:[NSNumber class]]) {
			[self setIsBackupEnabled:[(NSNumber* )theValue boolValue]];
		}
		if([theKey isEqual:@"backupTimeInterval"] && [theValue isKindOfClass:[NSNumber class]]) {
			[self setBackupTimeInterval:[(NSNumber* )theValue doubleValue]];
		}
		if([theKey isEqual:@"backupFreeSpacePercent"] && [theValue isKindOfClass:[NSNumber class]]) {
			[self setBackupFreeSpacePercent:[(NSNumber* )theValue unsignedIntegerValue]];
		}
		if([theKey isEqual:@"isRemoteAccess"] && [theValue isKindOfClass:[NSNumber class]]) {
			[self setIsRemoteAccess:[(NSNumber* )theValue boolValue]];
		}
		if([theKey isEqual:@"serverPort"] && [theValue isKindOfClass:[NSNumber class]]) {
			[self setServerPort:[(NSNumber* )theValue unsignedIntegerValue]];			
		}
	}
}

-(void)_saveSettingsToUserDefaults {
	// Save to system settings to dictionary
	NSMutableDictionary* thePreferences = [NSMutableDictionary dictionary];	
	[thePreferences setObject:[NSNumber numberWithBool:[self isBackupEnabled]] forKey:@"isBackupEnabled"];
	[thePreferences setObject:[NSNumber numberWithDouble:[self backupTimeInterval]] forKey:@"backupTimeInterval"];
	[thePreferences setObject:[NSNumber numberWithUnsignedInteger:[self backupFreeSpacePercent]] forKey:@"backupFreeSpacePercent"];
	[thePreferences setObject:[NSNumber numberWithBool:[self isRemoteAccess]] forKey:@"isRemoteAccess"];
	[thePreferences setObject:[NSNumber numberWithUnsignedInteger:[self serverPort]] forKey:@"serverPort"];	
	[thePreferences writeToFile:[self _settingsPath] atomically:YES];
}

-(BOOL)_connectClientUsingPassword:(NSString* )thePassword {
	[self setClient:[[[FLXPostgresConnection alloc] init] autorelease]];
	// client connection is always done through sockets	
	[[self client] setUser:[FLXServer superUsername]];
	[[self client] setDatabase:[FLXServer superUsername]];
	
	@try {
		[[self client] connectWithPassword:thePassword];
	} @catch(NSException* theException) {
		return NO;
	}
	return YES;
}

-(BOOL)_setClientPassword:(NSString* )thePassword {
	NSParameterAssert([[self client] connected]);
	@try {
		[[self client] execute:[NSString stringWithFormat:@"ALTER USER %@ WITH PASSWORD %@",[FLXServer superUsername],[[self client] quote:thePassword]]];
	} @catch(NSException* theException) {
		[self serverMessage:[NSString stringWithFormat:@"Unable to perform password change in database server: %@",theException]];
		return NO;		
	}	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	// release objects
	[self setDataPath:nil];
	[self setBackupPath:nil];
	[self setLastBackupTime:nil];
	[self setConnection:nil];
	[self setClient:nil];
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
	
	// set up keychain
	PostgresServerKeychain* theKeychain = [[[PostgresServerKeychain alloc] initWithDataPath:[self dataPath] serviceName:PostgresServerAppIdentifier] autorelease];
	[self setKeychain:theKeychain];
	[[self keychain] setDelegate:self];
	
	// success
	return YES;
}

-(void)endThread {
	// save user defaults here
	[self _saveSettingsToUserDefaults];
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

-(BOOL)setSuperuserPassword:(NSString* )theNewPassword existingPassword:(NSString* )theOldPassword {
	// retrieve existing password
	NSString* theExistingPassword = [[self keychain] passwordForAccount:[FLXServer superUsername]];
	if(theExistingPassword==nil) {
		[self serverMessage:@"Unable to retrieve the existing superuser password, assuming not yet set"];
	} else if([theExistingPassword isEqual:theOldPassword]==NO) {
		[self serverMessage:@"Existing superuser password does not match"];
		return NO;
	}

	// connect to database using this account
	NSString* theCurrentPassword;
	if([self _connectClientUsingPassword:theExistingPassword]==YES) {
		theCurrentPassword = theExistingPassword;
	} else if([self _connectClientUsingPassword:theNewPassword]==YES) {
		theCurrentPassword = theNewPassword;
	} else {
		// unable to login to database using either password, so barf
		[self serverMessage:@"Unable to login to database to perform password change"];
		[[self client] disconnect];
		return NO;
	}
	
	// set the password in the server
	if([self _setClientPassword:theNewPassword]==NO) {
		[[self client] disconnect];
		return NO;
	}
	
	// set new password
	BOOL isSuccess = [[self keychain] setPassword:theNewPassword forAccount:[FLXServer superUsername]];
	if(isSuccess==YES) {
		[self serverMessage:@"Success when setting new superuser password"];
	} else {
		[self serverMessage:@"Unable to set new superuser password, rolling back"];
		// rollback server change
		[self _setClientPassword:theCurrentPassword];
	}
	
	// disconnect client
	[[self client] disconnect];
	
	// return success condition
	return isSuccess;	
}

-(BOOL)hasSuperuserPassword {
	// retrieve existing password
	NSString* theExistingPassword = [[self keychain] passwordForAccount:[FLXServer superUsername]];
	return ([theExistingPassword length]==0) ? NO : YES;
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

-(NSUInteger)dataSpaceFreeAsPercent {
	NSParameterAssert([self dataPath]);
	NSDictionary* theDictionary = [[NSFileManager defaultManager] fileSystemAttributesAtPath:[self dataPath]];
	if(theDictionary==nil) return 0;
	unsigned long long theTotalBytes = [[theDictionary objectForKey:NSFileSystemSize] unsignedLongLongValue];
	unsigned long long theFreeBytes = [[theDictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
	double thePercentFree = (double)theFreeBytes * 100.0 / (double)theTotalBytes;
	return (NSUInteger)floor(thePercentFree);
}

-(NSUInteger)backupSpaceUsedAsPercentWithAdditionalSize:(unsigned long long)theBytes {
	NSParameterAssert([self backupPath]);
	NSDictionary* theDictionary = [[NSFileManager defaultManager] fileSystemAttributesAtPath:[self backupPath]];
	if(theDictionary==nil) return 0;
	unsigned long long theTotalBytes = [[theDictionary objectForKey:NSFileSystemSize] unsignedLongLongValue];
	unsigned long long theFreeBytes = [[theDictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
	double thePercentFree = (double)(theFreeBytes - theBytes) * 100.0 / (double)theTotalBytes;
	return (NSUInteger)(100 - floor(thePercentFree));
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
	unsigned long long theLastFileSize = 0;
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
			theLastFileSize = [[theEnumerator fileAttributes] fileSize];
		}
	}
	// no backup performed if backupTimeInterval not reached
	if(theLastFileDate !=nil && [[NSDate date] timeIntervalSinceDate:theLastFileDate] < [self backupTimeInterval]) {
		return;
	}
	
	// test purge
	NSUInteger thePercentUsed = [self backupSpaceUsedAsPercentWithAdditionalSize:theLastFileSize];
	if(thePercentUsed >= [self backupFreeSpacePercent]) {
		// TODO: perform the free space purge
		NSLog(@"TODO: purge backup directory %@",theDirectory);
	}

	// write the file
	[self serverMessage:@"Initiating backup"];

	// perform backup in background
	NSString* thePassword = [[self keychain] passwordForAccount:[FLXServer superUsername]];
	[[self server] backupInBackgroundToFolderPath:theDirectory superPassword:thePassword];
}

////////////////////////////////////////////////////////////////////////////////

-(void)keychainError:(NSError* )theError {
	NSLog(@"keychain error: %d: %@",[theError code],[theError localizedDescription]);	
}

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
