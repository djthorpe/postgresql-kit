
#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum {
	PGTokenizerHash = 1,
	PGTokenizerEquals,
	PGTokenizerComma,
	PGTokenizerSQString,
	PGTokenizerDQString,
	PGTokenizerOctal,
	PGTokenizerDecimal,
	PGTokenizerFloat,
	PGTokenizerKeyword,
	PGTokenizerWhitespace,
	PGTokenizerNewline,
	PGTokenizerIP4Addr,
	PGTokenizerIPMask,
	PGTokenizerIP6Addr,
	PGTokenizerHostname,
	PGTokenizerGroupMap,
	PGTokenizerOther
} PGTokenizerType;

////////////////////////////////////////////////////////////////////////////////

@interface PGTokenizerValue : NSObject {
	PGTokenizerType _type;
	NSString* _text;
}

+(PGTokenizerValue* )valueWithText:(const char* )text type:(PGTokenizerType)type;

@property (readonly) PGTokenizerType type;
@property (readonly) NSString* text;

-(NSString* )stringValue;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGTokenizerLine : NSObject {
	NSMutableString* _text;
}

@property BOOL eject;

-(void)append:(const char* )text;
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
-(BOOL)remove:(PGTokenizerLine* )line;
-(BOOL)load;
-(BOOL)save;

// line factory
-(PGTokenizerLine* )lineFactory;

@end
