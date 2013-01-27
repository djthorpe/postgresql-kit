
#import <Foundation/Foundation.h>

// initialize and destroy lookup cache
void pgdata2obj_init();
void pgdata2obj_destroy();

// public methods to convert
id pgdata_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id pgdata_text2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
