
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

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
	CFRelease(result);
}

@end

