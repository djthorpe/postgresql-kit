
#import "Terminal.h"
#include <readline/readline.h>
#include <readline/history.h>
#include <sys/ioctl.h>

NSInteger DEFAULT_COLUMNS = 120;

@implementation Terminal

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize prompt;
@dynamic columns;

-(NSInteger)columns {
	struct winsize w;
	ioctl(STDOUT_FILENO,TIOCGWINSZ, &w);
	if(w.ws_col < 10 || w.ws_col > 200) {
		return DEFAULT_COLUMNS;
	} else {
		return w.ws_col;
	}
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

