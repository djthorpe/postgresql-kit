
#include <sys/sysctl.h>
#include <pg_config.h>
#import "PGServerKit.h"
#import "PGServer+Private.h"

NSUInteger PGServer2DefaultPort = DEF_PGPORT;

@implementation PGServer2

@dynamic version;

////////////////////////////////////////////////////////////////////////////////
// initialization methods

+(PGServer* )sharedServer {
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
		[self setDelegate:nil];
		_state = PGServerStateUnknown;
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////
// private methods for returning information

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

+(NSString* )_dumpBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/pg_dumpall"];
}

+(NSString* )_superUsername {
	return @"postgres";
}

////////////////////////////////////////////////////////////////////////////////
// property implementation

-(NSString* )version {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[PGServer2 _serverBinary]];
	[theTask setArguments:[NSArray arrayWithObject:@"--version"]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[PGServer2 _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// get the version number
	[theTask launch];
	
	NSMutableData* theVersion = [NSMutableData data];
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[theVersion appendData:theData];
	}
	
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];
	if(theReturnCode==0 && [theVersion length]) {
		return [[NSString alloc] initWithData:theVersion encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
// start server method

-(BOOL)startWithDataPath:(NSString* )thePath {
	return [self startWithDataPath:thePath hostname:nil port:0];
}

-(BOOL)startWithDataPath:(NSString* )thePath hostname:(NSString* )hostname port:(NSUInteger)port {
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
// stop, reload and restart server

-(BOOL)stop {
	return NO;
}

-(BOOL)restart {
	return NO;
}

-(BOOL)reload {
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
// utility methods

+(NSString* )stateAsString:(PGServerState)theState {
	switch(theState) {
		case PGServerStateStopped:
			return @"PGServerStateStopped";
		case PGServerStateStopping:
			return @"PGServerStateStopping";
		case PGServerStateStarting:
		case PGServerStateIgnition:
			return @"PGServerStateStarting";
		case PGServerStateInitialize:
			return @"PGServerStateInitialize";
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			return @"PGServerStateRunning";
		case PGServerStateUnknown:
			return @"PGServerStateUnknown";
		case PGServerStateError:
			return @"PGServerStateError";
		default:
			return @"????";
	}
}

@end
