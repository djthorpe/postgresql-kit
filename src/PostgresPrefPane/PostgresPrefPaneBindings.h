//
//  PostgresPrefPaneBindings.h
//  postgresql
//
//  Created by David Thorpe on 27/02/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PostgresPrefPaneBindings : NSObject {
	NSString* bindServerVersion;
	NSString* bindServerStatus;
	NSString* bindDiskUsage;	
	NSImage* bindServerStatusImage;	
	NSUInteger bindServerPort;
	NSUInteger bindServerPortMinValue;
	NSUInteger bindServerPortMaxValue;
	BOOL bindServerPortEnabled;	
	BOOL bindIsRemoteAccess;
	BOOL bindIsRemoteAccessEnabled;
	NSInteger bindPortMatrixIndex;
	BOOL bindPortMatrixEnabled;		
	BOOL bindIsBackupEnabled;	
	NSInteger bindBackupIntervalTag;
	BOOL bindBackupIntervalEnabled;	
	NSInteger bindBackupFreeSpaceTag;
	BOOL bindBackupFreeSpaceEnabled;		
	BOOL bindStartButtonEnabled;
	BOOL bindStopButtonEnabled;
	BOOL bindInstallButtonEnabled;
	BOOL bindUninstallButtonEnabled;
	NSInteger bindTabViewIndex;	
	NSString* bindNewPassword;
	NSString* bindNewPassword2;
	NSString* bindExistingPassword;
	BOOL bindPasswordButtonEnabled;
	NSString* bindPasswordMessage;
}

@property (retain) NSString* bindServerVersion;
@property (retain) NSString* bindServerStatus;
@property (retain) NSString* bindDiskUsage;
@property (retain) NSImage* bindServerStatusImage;

@property (assign) NSUInteger bindServerPort;
@property (assign) NSUInteger bindServerPortMinValue;
@property (assign) NSUInteger bindServerPortMaxValue;
@property (assign) BOOL bindServerPortEnabled;

@property (assign) BOOL bindIsRemoteAccess;
@property (assign) BOOL bindIsRemoteAccessEnabled;

@property (assign) NSInteger bindPortMatrixIndex;
@property (assign) BOOL bindPortMatrixEnabled;

@property (assign) NSInteger bindTabViewIndex;

@property (assign) BOOL bindIsBackupEnabled;
@property (assign) NSInteger bindBackupIntervalTag;
@property (assign) BOOL bindBackupIntervalEnabled;
@property (assign) NSInteger bindBackupFreeSpaceTag;
@property (assign) BOOL bindBackupFreeSpaceEnabled;

@property (assign) BOOL bindStartButtonEnabled;
@property (assign) BOOL bindStopButtonEnabled;
@property (assign) BOOL bindInstallButtonEnabled;
@property (assign) BOOL bindUninstallButtonEnabled;

@property (retain) NSString* bindNewPassword;
@property (retain) NSString* bindNewPassword2;
@property (retain) NSString* bindExistingPassword;
@property (assign) BOOL bindPasswordButtonEnabled;
@property (retain) NSString* bindPasswordMessage;

// methods
-(void)setBackupIntervalTagFromInterval:(NSTimeInterval)theInterval;
-(NSTimeInterval)backupTimeIntervalFromTag;

-(void)setBackupFreeSpaceTagFromPercent:(NSInteger)thePercent;
-(NSInteger)backupFreeSpacePercentFromTag;

-(NSString* )existingPassword;
-(NSString* )newPassword;

@end
