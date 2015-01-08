
#import "Terminal.h"
#include <readline/readline.h>
#include <readline/history.h>

NSInteger DEFAULT_COLUMNS = 120;

@implementation Terminal

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize prompt;
@dynamic columns;

-(NSInteger)columns {
	return DEFAULT_COLUMNS;
/*	NSString* columns = [[[NSProcessInfo processInfo] environment] objectForKey:@"COLUMNS"];
	NSLog(@"cols = %@",[[NSProcessInfo processInfo] environment]);
	if(columns==nil) {
	}
	return [columns integerValue];
*/
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )readline {
	const char* p = [[self prompt] UTF8String];
	char* line = readline(p);
	if(line==nil) {
		return nil;
	}
	return [[NSString alloc] initWithBytesNoCopy:line length:strlen(line) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

-(void)addHistory:(NSString* )line {
	add_history([line UTF8String]);
}

-(void)printf:(NSString* )format,... {
	CFStringRef result;
    va_list arglist;
    va_start(arglist,format);
    result = CFStringCreateWithFormatAndArguments(NULL, NULL,(CFStringRef)format,arglist);
    va_end(arglist);
	printf("%s\n",[(__bridge NSString* )result UTF8String]);
}

@end

