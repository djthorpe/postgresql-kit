
#import <Foundation/Foundation.h>

typedef struct {
	NSUInteger oid;
	id (*bin2obj)(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
	id (*text2obj)(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
	const char* name;
} PGResultConverterType;

typedef struct {
	const char* name;
	const void* (*obj2bin)(id obj,NSUInteger* type,NSUInteger* size,BOOL* freeWhenDone,NSStringEncoding encoding);
	const void* (*obj2text)(id obj,NSUInteger* type,NSUInteger* size,BOOL* freeWhenDone,NSStringEncoding encoding);
} PGObjectConverterType;

