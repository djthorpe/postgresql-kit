
#import <Foundation/Foundation.h>

typedef struct {
	NSUInteger oid;
	id (*bin2obj)(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
	id (*text2obj)(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
	const char* name;
} PGResultConverterType;

