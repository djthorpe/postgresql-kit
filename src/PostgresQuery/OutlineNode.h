//
//  OutlineNode.h
//  postgresql
//
//  Created by David Thorpe on 08/06/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OutlineNode : NSObject {
	NSString* m_theType;
	NSString* m_theName;
	NSMutableArray* m_theChildren;
}

+(OutlineNode* )rootNodeWithName:(NSString* )theName;
+(OutlineNode* )schemaNodeWithName:(NSString* )theName;
+(OutlineNode* )schemaNodeAll;
+(OutlineNode* )tableNodeWithName:(NSString* )theName;
+(OutlineNode* )queryNodeWithName:(NSString* )theName;

-(NSString* )name;
-(NSMutableArray* )children;
-(void)setChildren:(NSMutableArray* )theChildren;
-(BOOL)isRootNode;
-(BOOL)isSchemaNode;
-(BOOL)isSchemaAllNode;
-(BOOL)isTableNode;
-(BOOL)isQueryNode;

@end
