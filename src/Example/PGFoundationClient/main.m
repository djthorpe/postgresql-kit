
/*
 This example shows how to use the PGClientKit to create a connection to a
 postgresql server, as a foundation shell tool.
 */

#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>


void handleSIGTERM(int signal) {
	NSLog(@"Handling sigterm");
}

void setHandleSignal() {
	// handle TERM and INT signals
	signal(SIGTERM,handleSIGTERM);
	signal(SIGINT,handleSIGTERM);
	signal(SIGKILL,handleSIGTERM);
	signal(SIGQUIT,handleSIGTERM);
}

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		// handle signals
		setHandleSignal();
		// create a connection
		PGClient* db = [[PGClient alloc] init];
		
		NSLog(@"Connecting");
		BOOL isSuccess = [db connectWithURL:[NSURL URLWithString:@"pgsql://postgres@localhost/"]];
		NSLog(@"Success = %@",isSuccess ? @"YES" : @"NO");
		NSLog(@"Disconnecting");
		[db disconnect];
	}
	
    return returnValue;
}
