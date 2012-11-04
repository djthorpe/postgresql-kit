
#import <Foundation/Foundation.h>

typedef enum {
	PGTokenizerHash = 1,
	PGTokenizerEquals,
	PGTokenizerSQString,
	PGTokenizerDQString,
	PGTokenizerKeyword,
	PGTokenizerWhitespace,
	PGTokenizerNewline,
	PGTokenizerOther
} PGTokenizerType;

@interface PGTokenizer : NSObject {
	NSMutableArray* _lines;
}
-(BOOL)parse:(NSString* )thePath;
-(void)token:(PGTokenizerType)type text:(const char* )text;
@end
