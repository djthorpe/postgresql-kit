//
//  OutlineNode.h
//  postgresql
//
//  Created by David Thorpe on 08/06/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OutlineNode : NSObject {
	NSString* m_theName;
	NSMutableArray* m_theChildren;
}

+(OutlineNode* )nodeWithName:(NSString* )theName;

-(NSString* )name;
-(NSMutableArray* )children;

@end
