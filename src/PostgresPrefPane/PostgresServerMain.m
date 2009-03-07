
#import <Foundation/Foundation.h>
#import "PostgresServerApp.h"

volatile int caughtSignal = 0;

void signalHandler(int signal) {
	caughtSignal = signal;
	if(caughtSignal > 0) {
		NSLog(@"Caught Signal, stopping NSRunLoop");
		CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
	}  
}

int main(int argc,char* argv[]) {
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	PostgresServerApp* theApp = [[PostgresServerApp alloc] init];
	int returnValue = 0;

	// catch signals
	signal(SIGTERM,signalHandler);

	// set the data path for postgres data from command line
	NSString* theDataPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"data"];
	if(theDataPath==nil) {
		NSArray* theSearchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSLocalDomainMask, YES);
		if([theSearchPaths count]==0) goto APP_EXIT;
		NSString* theProcessName = [[NSProcessInfo processInfo] processName];
		theDataPath = [(NSString* )[theSearchPaths objectAtIndex:0] stringByAppendingPathComponent:theProcessName];
	}	

	NSString* theBackupPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"backup"];
	if(theBackupPath==nil) {
		theBackupPath = theDataPath;
	}
		
	[theApp setDataPath:theDataPath];
	[theApp setBackupPath:theBackupPath];
	
	// awake the app
	if([theApp awakeThread]==NO) {
		returnValue = -1;
		NSLog(@"Unable to start the application");
		goto APP_EXIT;
	}

	NSLog(@"    Version = %@",[theApp serverVersion]);
	NSLog(@"  Data path = %@",theDataPath);
	NSLog(@"Backup path = %@",theBackupPath);
	
	NSLog(@"Starting NSRunLoop");
	
	// start  the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		// run the loop!
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
		// occasionally re-create the autorelease pool whilst program is running
		[thePool release];
		thePool = [[NSAutoreleasePool alloc] init];            
	} while(isRunning==YES && caughtSignal==0);  

	NSLog(@"Stopped NSRunLoop");
	
	// stop the server
	while([[theApp server] isRunning]) {
		NSLog(@"Stopping the server");
		[theApp stopServer];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}	

	// perform cleanup
	[theApp endThread];		
	
APP_EXIT:
	[theApp release];
	[thePool release];
	return returnValue;
}