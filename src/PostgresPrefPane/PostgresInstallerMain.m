
#import <Foundation/Foundation.h>
#include <unistd.h>

////////////////////////////////////////////////////////////////////////////////

@interface PostgresInstallerApp : NSObject {
	
}

// static methods
+(NSInteger)installForPath:(NSString* )thePath;
+(NSInteger)uninstallForPath:(NSString* )thePath;
+(BOOL)restorePermissionsForPath:(NSString* )thePath ownerAccountName:(NSString* )theOwnerAccountName posixPermissions:(NSNumber* )thePosixPermissions;
+(NSDictionary* )addStickyBitForPath:(NSString* )thePath;
+(NSInteger)executeTask:(NSString* )theProgramPath arguments:(NSArray* )theArguments;
+(NSString* )plistPathForBundlePath:(NSString* )theBundlePath;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PostgresInstallerApp

+(NSString* )plistName {
	return @"PostgresPrefPaneServerStartupItem";
}

+(NSString* )launchDaemonsPath {
	return @"/Library/LaunchDaemons";
}

+(NSString* )launchDaemonsFilename {
	return [@"com.mutablelogic.postgreSQL" stringByAppendingPathExtension:@"plist"];
}

+(NSString* )appFilename {
	return @"PostgresServerApp";
}

+(NSString* )dataPath {
	return @"/Library/Application Support/PostgreSQL";
}

+(NSString* )plistFilename {
	return [[self plistName] stringByAppendingPathExtension:@"plist"];
}


+(NSString* )plistPathForBundlePath:(NSString* )theBundlePath {
	return [[theBundlePath stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:[self plistFilename]];
}

+(NSString* )appPathForBundlePath:(NSString* )theBundlePath {
	return [[theBundlePath stringByAppendingPathComponent:@"Contents/MacOS"] stringByAppendingPathComponent:[self appFilename]];
}

+(NSString* )plistPathForLaunchDaemons {
	return [[self launchDaemonsPath] stringByAppendingPathComponent:[self launchDaemonsFilename]];
}

+(NSInteger)installForPath:(NSString* )thePath {
	NSError* theError = nil;	
	
	// check for existing launch daemon file
	if([[NSFileManager defaultManager] fileExistsAtPath:[self plistPathForLaunchDaemons]]==YES) {
		NSInteger retVal = [self uninstallForPath:thePath];
		if(retVal != 0) {
			NSLog(@"Unable to uninstall existing installation");
			return -1;
		}
	}	
	// check for plist file
	if([[NSFileManager defaultManager] fileExistsAtPath:[self plistPathForBundlePath:thePath]]==NO) {
		NSLog(@"Launch item does not exist: %@",[self plistPathForBundlePath:thePath]);
		return -1;
	}
	// check for app file, and is executable
	if([[NSFileManager defaultManager] fileExistsAtPath:[self appPathForBundlePath:thePath]]==NO) {
		NSLog(@"Application does not exist: %@",[self appPathForBundlePath:thePath]);
		return -1;
	}	
	if([[NSFileManager defaultManager] isExecutableFileAtPath:[self appPathForBundlePath:thePath]]==NO) {
		NSLog(@"Application is not executable: %@",[self appPathForBundlePath:thePath]);
		return -1;	
	}	
	
	// copy plist file to launch directory
	if([[NSFileManager defaultManager] copyItemAtPath:[self plistPathForBundlePath:thePath] toPath:[self plistPathForLaunchDaemons] error:&theError]==NO) {
		NSLog(@"Launch item copy error: %@",[theError localizedDescription]);
		return -1;		
	}
	// write out path to application and path to data, convert to XML format
	int retVal = [self executeTask:@"/usr/bin/defaults" arguments:[NSArray arrayWithObjects:@"write",[[self plistPathForLaunchDaemons] stringByDeletingPathExtension],@"ProgramArguments",@"-array",[self appPathForBundlePath:thePath],@"-string",@"-data",[self dataPath],nil] ];
	if(retVal != 0) {
		NSLog(@"Defaults write error");
		return -1;
	}
	retVal = [self executeTask:@"/usr/bin/plutil" arguments:[NSArray arrayWithObjects:@"-convert",@"xml1",[self plistPathForLaunchDaemons],nil]];
	if(retVal != 0) {
		NSLog(@"plutil write error");
		return -1;
	}		
	// change permissions on the file
	if([self restorePermissionsForPath:[self plistPathForLaunchDaemons] ownerAccountName:@"root" posixPermissions:[NSNumber numberWithInt:0644]]==NO) {
		NSLog(@"Unable to set permissions for file");
		return -1;		
	}

	
	
	// perform the load	
	NSInteger oldUID = getuid();
	setuid(0);
	retVal = [self executeTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load",[self plistPathForLaunchDaemons],nil]];
	setuid(oldUID);
	if(retVal != 0) {
		NSLog(@"launchctl load error");
		return -1;
	}		
	return 0;
}

+(NSInteger)uninstallForPath:(NSString* )thePath {
	NSError* theError = nil;	
	
	/* TODO: see if service is loaded return=0 yes
	launchctl list ${LAUNCHCTL_LABEL} 2>&1 1>/dev/null
	if [ z"$?" == z"0" ]
		then
		launchctl unload ${PATH_PLIST_DEST}
	fi
	*/

	// check for existing launch daemon file
	if([[NSFileManager defaultManager] fileExistsAtPath:[self plistPathForLaunchDaemons]]==NO) {
		return 0;
	}
	
	// unload
//	NSInteger oldUID = getuid();
//	setuid(0);
	NSInteger retVal = [self executeTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload",[self plistPathForLaunchDaemons],nil]];
//	setuid(oldUID);
	if(retVal != 0) {
		NSLog(@"launchctl unload error");
		return -1;
	}		
	
	// remove existing file
	if([[NSFileManager defaultManager] removeItemAtPath:[self plistPathForLaunchDaemons] error:&theError]==NO) {
		NSLog(@"Launch item remove error: %@",[theError localizedDescription]);	
		return -1;
	}

	// success
	return 0;
}

+(BOOL)restorePermissionsForPath:(NSString* )thePath ownerAccountName:(NSString* )theOwnerAccountName posixPermissions:(NSNumber* )thePosixPermissions {
	// ensure the path is to an executable file
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO || isDirectory==YES) {
		NSLog(@"Invalid: %@",thePath);
		return NO;
	}	
		
	// perform the restoration
	NSError* theError = nil;
	NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:thePosixPermissions,NSFilePosixPermissions,theOwnerAccountName,NSFileOwnerAccountName,nil];
	if([[NSFileManager defaultManager] setAttributes:theAttributes ofItemAtPath:thePath error:&theError]==NO) {
		NSLog(@"Error: %@",[theError localizedDescription]);
		return NO;		
	}
	
	// success (we think!)
	return YES;	
}

+(NSDictionary* )addStickyBitForPath:(NSString* )thePath {
	NSError* theError = nil;
	BOOL isDirectory;

	// ensure the path is to an executable file
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO || isDirectory==YES) {
		NSLog(@"Invalid: %@",thePath);
		return nil;
	}
	if([[NSFileManager defaultManager] isExecutableFileAtPath:thePath]==NO) {
		NSLog(@"Not executable: %@",thePath);
		return nil;
	}
	// store a copy of the old permissions
	NSDictionary* theAttributes0 = [[NSFileManager defaultManager] attributesOfItemAtPath:thePath error:&theError];
	if(theAttributes0==nil) {
		NSLog(@"Error: %@",[theError localizedDescription]);
		return nil;				
	}
	// perform the chown
	NSDictionary* theAttributes1 = [NSDictionary dictionaryWithObjectsAndKeys:@"root",NSFileOwnerAccountName,nil];
	if([[NSFileManager defaultManager] setAttributes:theAttributes1 ofItemAtPath:thePath error:&theError]==NO) {
		NSLog(@"Error: %@",[theError localizedDescription]);
		return nil;		
	}
	// perform the chmod
	NSDictionary* theAttributes2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:04711],NSFilePosixPermissions,nil];
	if([[NSFileManager defaultManager] setAttributes:theAttributes2 ofItemAtPath:thePath error:&theError]==NO) {
		NSLog(@"Error: %@",[theError localizedDescription]);
		return nil;		
	}	
	// success (we think!)
	return theAttributes0;	
}

+(NSInteger)executeTask:(NSString* )theProgramPath arguments:(NSArray* )theArguments {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init]; 
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:theProgramPath];  
	[theTask setArguments:theArguments];
	[theTask launch];                                                 
	
	NSMutableData* theReturnedData = [NSMutableData data];
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[theReturnedData appendData:theData];
	}  
	// wait until task is actually completed
	[theTask waitUntilExit];
	NSInteger theReturnCode = [theTask terminationStatus];    
	[theTask release];
	[theOutPipe release];    

	//NSString* theOutput = [[NSString alloc] initWithData:theReturnedData encoding:NSUTF8StringEncoding];
	//NSLog(@"%@",theOutput);
	//[theOutput release];	
	
	return theReturnCode;
}

@end

////////////////////////////////////////////////////////////////////////////////

int main(int argc,char* argv[]) {
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	NSInteger returnValue = 0;
	NSInteger argCount = [[[NSProcessInfo processInfo] arguments] count];
	NSString* theProgramPath = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
	NSString* theProgramName = [theProgramPath lastPathComponent];
	NSString* theBundlePath = [[[theProgramPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"../.."] stringByStandardizingPath];

	// parse arguments from command line
	NSString* theCommand = (argCount < 2) ? nil : [[[NSProcessInfo processInfo] arguments] objectAtIndex:1];
	NSString* theOwnerAccountName = (argCount < 3) ? nil : [[[NSProcessInfo processInfo] arguments] objectAtIndex:2];
	NSNumber* thePosixPermissions = (argCount < 4) ? nil : [NSDecimalNumber decimalNumberWithString:[[[NSProcessInfo processInfo] arguments] objectAtIndex:3]];
	
	NSLog(@"%@ %@ uid=%d euid=%d",theProgramName,theCommand,getuid(),geteuid());
	
	// perform operations
	if([theCommand length]==0) {
		goto APP_SYNTAX_ERROR;
	}
	if([theCommand isEqual:@"suid-install"]) {
		returnValue = [PostgresInstallerApp installForPath:theBundlePath];
		if([PostgresInstallerApp restorePermissionsForPath:theProgramPath ownerAccountName:theOwnerAccountName posixPermissions:thePosixPermissions]==NO) {
			NSLog(@"Error: unable to remove suid bit for path: %@",theProgramPath);
			returnValue = -1;
		}
		goto APP_EXIT;
	}
	if([theCommand isEqual:@"suid-uninstall"]) {
		returnValue = [PostgresInstallerApp uninstallForPath:theBundlePath];
		if([PostgresInstallerApp restorePermissionsForPath:theProgramPath ownerAccountName:theOwnerAccountName posixPermissions:thePosixPermissions]==NO) {
			NSLog(@"Error: unable to remove suid bit for path: %@",theProgramPath);
			returnValue = -1;
		}
		goto APP_EXIT;
	}
	if([theCommand isEqual:@"install"] || [theCommand isEqual:@"uninstall"]) {	
		NSDictionary* theOldAttributes = [PostgresInstallerApp addStickyBitForPath:theProgramPath];
		if(theOldAttributes==nil) {
			NSLog(@"Error: unable to add suid bit for path: %@",theProgramPath);
			returnValue = -1;
		} else {
			returnValue = [PostgresInstallerApp executeTask:theProgramPath arguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"suid-%@",theCommand],[theOldAttributes objectForKey:NSFileOwnerAccountName],[[theOldAttributes objectForKey:NSFilePosixPermissions] description],nil]];
		}
		if(returnValue==0) {
			NSLog(@"%@: OK",theCommand);
		}
		goto APP_EXIT;
	}
APP_SYNTAX_ERROR:
	NSLog(@"Syntax: %@ (install | uninstall)",theProgramName);
	returnValue = -1;
APP_EXIT:
	[thePool release];
	return returnValue;
}