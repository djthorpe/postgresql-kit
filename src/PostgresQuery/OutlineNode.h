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
}

+(OutlineNode* )nodeWithName:(NSString* )theName;

@end
