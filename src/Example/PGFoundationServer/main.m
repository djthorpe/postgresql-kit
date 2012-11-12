
/*
 This example shows how to use the PGServerKit to create a server, as
 a foundation shell tool. When the server is started, any signal (TERM or KILL)
 is handled to stop the server gracefully.
*/

#import <Foundation/Foundation.h>
#import "PGFoundationServer.h"

////////////////////////////////////////////////////////////////////////////////

static PGFoundationServer* controller = nil;

void handleSIGTERM(int signal) {
	printf("Caught signal: %d\n",signal);
	[controller stop];
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
		// delegate object
		controller = [[PGFoundationServer alloc] init];
		// run loop
		returnValue = [controller start];
	}

    return returnValue;
}
