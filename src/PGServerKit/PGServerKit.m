
#import "PGServerKit.h"

const uint64 PGDefaultPort = 100;

@implementation PGServerKit

////////////////////////////////////////////////////////////////////////////////
// initialization methods

+(PGServerKit* )sharedServer {
    static dispatch_once_t pred = 0;
    __strong static id _sharedServer = nil;
    dispatch_once(&pred, ^{
        _sharedServer = [[self alloc] init];
    });
    return _sharedServer;
}

-(id)init {
	self = [super init];
	if(self) {
        self.port = PGDefaultPort;
        self.delegate = nil;
		self.state = PGServerStateUnknown;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods to return paths to things within the framework

+(NSString* )_bundlePath {
	return [[NSBundle bundleForClass:[self class]] bundlePath];
}

+(NSString* )_serverBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/postgres"];
}

+(NSString* )_initBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/initdb"];
}

+(NSString* )_libraryPath {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/lib"];
}

////////////////////////////////////////////////////////////////////////////////
// private method to return the PID of the running postgresql process

-(int)_pidFromDataPath {
	NSString* thePath = [[self dataPath] stringByAppendingPathComponent:@"postmaster.pid"];
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath]==NO) {
		// no postmaster.pid file found, therefore no process
		return 0;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:thePath]==NO) {
		// if postmaster.pid is not readable, return error
		return -1;
	}
	NSDictionary* theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thePath error:nil];
	if(theAttributes==nil || [theAttributes fileSize] > 1024) {
		// if postmaster.pid file is too large, return error
		return -1;
	}
	NSError* theError = nil;
	NSString* thePidString = [NSString stringWithContentsOfFile:thePath encoding:NSUTF8StringEncoding error:&theError];
	if(thePidString==nil) {
		// if postmaster.pid file could not be read, return error
		return -1;
	}
	
	// return the PID as a decimal number
	NSDecimalNumber* thePid = [NSDecimalNumber decimalNumberWithString:thePidString];
	if(thePid==nil) {
		// if postmaster.pid file does not contain a valid decimal number, return
		return -1;
	}
	
	// success - return decimal number
	return [thePid intValue];
}

////////////////////////////////////////////////////////////////////////////////
// private method to create data path if it doesn't exist

-(BOOL)_createDataPath:(NSString* )thePath {
	// if directory already exists
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO) {
		// create the directory
		if([[NSFileManager defaultManager] createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:nil error:nil]==NO) {
			return NO;
		}
	} else if(isDirectory==NO) {
		return NO;
	}
	
	// success - return yes
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)startWithDataPath:(NSString* )thePath {
	NSParameterAssert(thePath);

	// TODO: check for running server
	
	// set the data path and the pid
	self.dataPath = thePath;
	self.pid = -1;
	
	// if database process is already running, then set this as the state and return NO
	int thePid = [self _pidFromDataPath];
	if(thePid > 0) {
		self.pid = thePid;
		self.state = PGServerStateStarted;
		return NO;
	}

	// if we received a minus one, an error occurred doing this step
	if(thePid < 0) {
		self.state = PGServerStateError;
		return NO;
	}
	
	// create the data path if nesessary
	if([self _createDataPath:[self dataPath]]==NO) {
		self.state = PGServerStateError;
		return NO;
	}
	
	// set the pid to zero
	self.pid = 0;
	self.state = PGServerStateUnknown;

	// start the background thread to start the server
	// TODO: [NSThread detachNewThreadSelector:@selector(_backgroundThread:) toTarget:self withObject:nil];
	
	// immediate return
	return YES;
}

@end
