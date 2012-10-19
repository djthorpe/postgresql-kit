
/*
 This example shows how to use the PGClientKit to create a connection to a
 postgresql server, as a foundation shell tool.
 */

#import <Foundation/Foundation.h>
#import "Application.h"

Application* app = nil;

void handleSIGTERM(int signal) {
	if(app) {
		NSLog(@"Handling sigterm");
		[app setSignal:-1];
	}
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

		// create an application, run it
		app = [[Application alloc] init];
		returnValue = [app run];
	}
	
	NSLog(@"Application is terminated, returnValue = %d",returnValue);	
    return returnValue;
}
