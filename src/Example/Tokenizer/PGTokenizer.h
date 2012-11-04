
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

-(BOOL)parseFile:(NSString* )thePath;
-(void)token:(PGTokenizerType)type text:(const char* )text;
@end

@interface PGTokenizerLine : NSObject {
	NSUInteger _state;
	NSMutableString* _text;
	NSString* _keyword;
	NSMutableString* _value;
	BOOL _enabled;
	NSMutableString* _comment;
}

@end

