//
//  main.m
//  Tokenizer
//
//  Created by David Thorpe on 04/11/2012.
//
//

#import <Foundation/Foundation.h>
#import "PGTokenizer.h"

// /Users/davidthorpe/Library/Application Support/PostgreSQL/pg_ident.conf
// /Users/davidthorpe/Library/Application Support PostgreSQL/pg_hba.conf
// /Users/davidthorpe/Library/Application Support/PostgreSQL/postgresql.conf

int main(int argc, const char * argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		// create tokenizer
		PGTokenizer* t = [[PGTokenizer alloc] init];
        // read filename from command line
        for(int arg=1; arg < argc; arg++) {
            NSString* thePath = [[NSString alloc] initWithUTF8String:argv[arg]];
			BOOL isSuccess = [t parseFile:thePath];
			if(isSuccess==NO) {
				returnValue = -1;
				break;
			}
        }
    }
    return returnValue;
}

