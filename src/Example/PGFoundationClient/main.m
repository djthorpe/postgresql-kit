
/*
 This example shows how to use the PGClientKit to create a connection to a
 postgresql server, as a foundation shell tool.
 */

#import <Foundation/Foundation.h>
#import "Application.h"

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

		// create an application, run it
		Application* app = [[Application alloc] init];		
		returnValue = [app run];
	}
	
    return returnValue;
}
