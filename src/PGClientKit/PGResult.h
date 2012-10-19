
#import <Foundation/Foundation.h>

@interface PGResult : NSObject {
	void* _result;
	PGClientTupleFormat _format;
	NSUInteger _rowNumber;
}

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger affectedRows;
@property (readonly) NSUInteger size;
@property (readwrite) NSUInteger rowNumber;
@property (readonly) BOOL dataReturned;
@property (readonly) NSArray* columnNames;
@property (readonly) PGClientTupleFormat format;

// fetch rows
-(NSArray* )fetchRowAsArray;

@end
