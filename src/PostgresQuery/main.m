
#import <Cocoa/Cocoa.h>

NSString* FLXCreateDatabaseNotification = @"FLXCreateDatabaseNotification";
NSString* FLXDropDatabaseNotification = @"FLXDropDatabaseNotification";
NSString* FLXSelectDatabaseNotification = @"FLXSelectDatabaseNotification";

int main(int argc, char *argv[]) {
	return NSApplicationMain(argc,(const char **)argv);
}
