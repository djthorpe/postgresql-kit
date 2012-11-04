//
//  main.m
//  Tokenizer
//
//  Created by David Thorpe on 04/11/2012.
//
//

#import <Foundation/Foundation.h>

// /Users/davidthorpe/Library/Application Support/PostgreSQL/pg_ident.conf
// /Users/davidthorpe/Library/Application Support PostgreSQL/pg_hba.conf
// /Users/davidthorpe/Library/Application Support/PostgreSQL/postgresql.conf

extern int file_tokenize(NSString* );

int main(int argc, const char * argv[]) {
	int returnValue = 0;
	@autoreleasepool {
        // read filename from command line
        for(int arg=1; arg < argc; arg++) {
            NSString* thePath = [[NSString alloc] initWithUTF8String:argv[arg]];
			returnValue = file_tokenize(thePath);
			if(returnValue) {
				break;
			}
        }
    }
    return returnValue;
}

