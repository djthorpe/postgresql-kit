//
//  PrefPanePref.h
//  PrefPane
//
//  Created by David Thorpe on 11/02/2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface PostgresPrefPaneController : NSPreferencePane {
	NSConnection* connection;	
	
	// IBOutlet
	IBOutlet NSTextField* ibVersionNumber;
	IBOutlet NSTextField* ibStatus;	
	IBOutlet NSTabView* ibTabView;
}

@property (retain) NSConnection* connection;

-(void)mainViewDidLoad;

// IBAction
-(IBAction)doStartServer:(id)sender;
-(IBAction)doStopServer:(id)sender;
-(IBAction)doInstall:(id)sender;
-(IBAction)doUninstall:(id)sender;

@end
