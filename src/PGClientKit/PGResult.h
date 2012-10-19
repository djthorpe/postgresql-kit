
#import <Foundation/Foundation.h>

@interface PGResult : NSObject {
	void* _result;
	NSUInteger _rowNumber;
}

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger affectedRows;
@property (readonly) NSUInteger size;
@property (readwrite) NSUInteger rowNumber;
@property (readonly) BOOL dataReturned;
@property (readonly) NSArray* columnNames;

// fetch rows
-(NSArray* )fetchRowAsArray;

@end
