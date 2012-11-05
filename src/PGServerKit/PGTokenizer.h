
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
	NSMutableDictionary* _index;
	NSMutableArray* _keywords;
	BOOL _modified;
}

// properties
@property (readonly) BOOL modified;
@property (readonly) NSInteger count;

// load/save methods
-(BOOL)load:(NSString* )thePath;
-(BOOL)save:(NSString* )thePath;

// access values methods
-(NSString* )keyAtIndex:(NSInteger)rowIndex;
-(BOOL)enabledForKey:(NSString* )theKey;
-(NSString* )commentForKey:(NSString* )theKey;
-(NSString* )valueForKey:(NSString* )theKey;
-(void)setValue:(NSString* )theValue forKey:(NSString* )theKey;
-(void)setEnabled:(BOOL)theValue forKey:(NSString* )theKey;

// private methods
-(void)token:(PGTokenizerType)type text:(const char* )text;

@end
