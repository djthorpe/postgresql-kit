
#import <Foundation/Foundation.h>

typedef struct {
	NSUInteger oid;
	id (*bin2obj)(NSUInteger oid,const void* bytes,NSUInteger size);
	const void* (*obj2bin)(NSUInteger oid,id object,NSUInteger* size);
	const char* name;
} PGResultConverterType;

id _pgresult_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size);
