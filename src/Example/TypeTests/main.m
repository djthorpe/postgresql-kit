
#import <Foundation/Foundation.h>
#import "Application.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	Application* app = [[Application alloc] initWithURL:[NSURL URLWithString:@"pgsql://postgres@/postgres"]];
	
	////////////////////////////////////////////////////////////////////////////

	@try {
		[app doWork];
	} @catch(NSException* theException) {
		NSLog(@"Exception caught: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[app release];
	[pool release];
	return 0;
}
