//
//  CreateDropDatabaseController.h
//  postgresql
//
//  Created by David Thorpe on 11/05/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CreateDropDatabaseController : NSObject {
	// properties
	NSString* m_theDatabase;
	
	// outlets
	IBOutlet NSWindow* m_theCreateSheet;
	IBOutlet NSWindow* m_theDropSheet;
}

// properties
-(NSString* )database;
-(void)setDatabase:(NSString* )theDatabase;

// methods
-(void)beginCreateDatabaseWithWindow:(NSWindow* )theWindow;
-(void)beginDropDatabaseWithWindow:(NSWindow* )theWindow;

// IBAction
-(IBAction)doEndSheet:(id)sender;

@end
