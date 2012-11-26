
#import <Foundation/Foundation.h>

typedef struct {
	NSUInteger oid;
	id (*bin2obj)(NSUInteger out,const void* bytes,NSUInteger size);
	id (*obj2bin)(NSUInteger out,const void* bytes,NSUInteger size);
	const char* name;
} PGResultConverterType;

extern PGResultConverterType _pgresult_default_converters[];
