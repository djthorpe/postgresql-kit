
#import <Foundation/Foundation.h>

@interface PGResult : NSObject {
	void* _result;
	PGClientTupleFormat _format;
	NSStringEncoding _encoding;
	NSUInteger _rowNumber;
	NSMutableDictionary* _cachedData;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger affectedRows;
@property (readonly) NSUInteger size;
@property (readwrite) NSUInteger rowNumber;
@property (readonly) BOOL dataReturned;
@property (readonly) NSArray* columnNames;
@property (readonly) PGClientTupleFormat format;

////////////////////////////////////////////////////////////////////////////////
// methods

// fetch rows
-(NSArray* )fetchRowAsArray;
-(NSDictionary* )fetchRowAsDictionary;

@end
