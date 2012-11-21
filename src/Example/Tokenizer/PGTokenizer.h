
#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum {
	PGTokenizerHash = 1,
	PGTokenizerEquals,
	PGTokenizerSQString,
	PGTokenizerDQString,
	PGTokenizerOctal,
	PGTokenizerDecimal,
	PGTokenizerFloat,
	PGTokenizerKeyword,
	PGTokenizerWhitespace,
	PGTokenizerNewline,
	PGTokenizerOther
} PGTokenizerType;

////////////////////////////////////////////////////////////////////////////////

@interface PGTokenizerLine : NSObject

@property (readonly) BOOL eject;

-(BOOL)parse:(PGTokenizerType)type text:(const char* )text;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGTokenizer : NSObject {
	NSString* _path;
	BOOL _modified;
	NSMutableArray* _lines;
}

// constructor
-(id)initWithPath:(NSString* )path;

// properties
@property (readonly) NSString* path;
@property (readonly) BOOL modified;
@property (readonly) NSArray* lines;

// public methods
-(BOOL)append:(PGTokenizerLine* )line;
-(BOOL)load;
-(BOOL)save;

// private(ish) methods
-(PGTokenizerLine* )line;

@end
