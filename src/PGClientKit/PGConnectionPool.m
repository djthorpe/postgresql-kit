
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

@implementation PGConnectionPool

////////////////////////////////////////////////////////////////////////////////
// initialization methods

+(PGConnectionPool* )sharedConnectionPool {
    static dispatch_once_t pred = 0;
    __strong static id _sharedConnectionPool = nil;
    dispatch_once(&pred, ^{
        _sharedConnectionPool = [[self alloc] init];
    });
    return _sharedConnectionPool;
}

-(id)init {
	self = [super init];
	if(self) {
		_hash = [NSMutableDictionary dictionary];
	}
	return self;
}

-(void)dealloc {
	[self removeAllConnections];
	_hash = nil;
}

////////////////////////////////////////////////////////////////////////////////

-(PGConnection* )connectionForHandle:(const void* )handle {
	NSParameterAssert(handle != nil);
	return [_hash objectForKey:[NSValue valueWithPointer:handle]];
}

-(void)addConnection:(PGConnection* )theConnection forHandle:(const void* )handle {
	NSParameterAssert(handle != nil);
	NSParameterAssert([self connectionForHandle:handle] == nil);
	[_hash setObject:theConnection forKey:[NSValue valueWithPointer:handle]];
}

-(void)removeConnectionForHandle:(const void* )handle {
	NSParameterAssert([self connectionForHandle:handle] != nil);
	[_hash removeObjectForKey:[NSValue valueWithPointer:handle]];
}

-(void)removeAllConnections {
	[_hash removeAllObjects];
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<PGConnectionPool: %lu connections>",[_hash count]];
}

@end
