
#import "NSTreeController+Utils.h"

// code implementation adapted from http://www.wilshipley.com/blog/2006/04/pimp-my-code-part-10-whining-about.html

@interface NSTreeController (UtilsPrivate)
-(NSIndexPath* )_indexPathFromIndexPath:(NSIndexPath* )baseIndexPath inChildren:(NSArray* )children childCount:(NSUInteger)childCount toObject:(id)object;
@end

@implementation NSTreeController (Utils)

-(void)setSelectedObjects:(NSArray* )newSelectedObjects {
	NSMutableArray* indexPaths = [NSMutableArray array];
	for(NSUInteger selectedObjectIndex = 0; selectedObjectIndex < [newSelectedObjects count]; selectedObjectIndex++) {
		id selectedObject = [newSelectedObjects objectAtIndex:selectedObjectIndex];
		NSIndexPath* indexPath = [self indexPathToObject:selectedObject];
		if(indexPath) {
			[indexPaths addObject:indexPath];			
		}
	}	
	[self setSelectionIndexPaths:indexPaths];
}

-(NSIndexPath* )indexPathToObject:(id)object {
	NSArray* children = [self content];
	return [self _indexPathFromIndexPath:nil inChildren:children childCount:[children count] toObject:object];
}

@end

@implementation NSTreeController (UtilsPrivate)

-(NSIndexPath* )_indexPathFromIndexPath:(NSIndexPath* )baseIndexPath inChildren:(NSArray* )children childCount:(NSUInteger)childCount toObject:(id)object {
	for (NSUInteger childIndex = 0; childIndex < childCount; childIndex++) {
		id childObject = [children objectAtIndex:childIndex];		
		NSArray* childsChildren = nil;
		NSUInteger childsChildrenCount = 0;
		NSString* leafKeyPath = [self leafKeyPath];
		if (!leafKeyPath || [[childObject valueForKey:leafKeyPath] boolValue] == NO) {
			NSString* countKeyPath = [self countKeyPath];
			if (countKeyPath) {
				childsChildrenCount = [[childObject valueForKey:leafKeyPath] unsignedIntegerValue];				
			}
			if (!countKeyPath || childsChildrenCount != 0) {
				NSString* childrenKeyPath = [self childrenKeyPath];
				childsChildren = [childObject valueForKey:childrenKeyPath];
				if (!countKeyPath) {
					childsChildrenCount = [childsChildren count];					
				}
			}
		}
		
		BOOL objectFound = [object isEqual:childObject];
		if (!objectFound && childsChildrenCount == 0) {
			continue;			
		}
		
		NSIndexPath* indexPath = (baseIndexPath == nil) ? [NSIndexPath indexPathWithIndex:childIndex] : [baseIndexPath indexPathByAddingIndex:childIndex];
		
		if(objectFound) {
			return indexPath;			
		}
		
		NSIndexPath* childIndexPath = [self _indexPathFromIndexPath:indexPath inChildren:childsChildren childCount:childsChildrenCount toObject:object];
		if (childIndexPath) {
			return childIndexPath;			
		}
	}
	
	return nil;
}

@end
