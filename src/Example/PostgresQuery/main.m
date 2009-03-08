
#import <Cocoa/Cocoa.h>

NSString* FLXCreateDatabaseNotification = @"FLXCreateDatabaseNotification";
NSString* FLXDropDatabaseNotification = @"FLXDropDatabaseNotification";
NSString* FLXSelectDatabaseNotification = @"FLXSelectDatabaseNotification";
NSString* FLXSelectSchemaNotification = @"FLXSelectSchemaNotification";

NSString* FLXNodeRoot = @"FLXNodeRoot";
NSString* FLXNodeSchema = @"FLXNodeSchema";
NSString* FLXNodeSchemaAll = @"FLXNodeSchemaAll";
NSString* FLXNodeTable = @"FLXNodeTable";
NSString* FLXNodeQuery = @"FLXNodeQuery";

int main(int argc, char *argv[]) {
	return NSApplicationMain(argc,(const char **)argv);
}
