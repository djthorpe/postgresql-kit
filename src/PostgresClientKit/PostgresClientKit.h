
/*
 
 Copyright 2008/2009 David Thorpe, djt@mutablelogic.com
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not 
 use this file except in compliance with the License. You may obtain a copy of 
 the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software 
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 License for the specific language governing permissions and limitations under
 the License.
 
 */

@class FLXPostgresConnection;
@class FLXPostgresStatement;
@class FLXPostgresResult;
@class FLXPostgresException;
@class FLXPostgresTypes;
@class FLXMacAddr;
@class FLXTimeInterval;
@class FLXPostgresArray;
@class FLXGeometry;
  @class FLXGeometryPoint;
  @class FLXGeometryLine;
  @class FLXGeometryBox;
  @class FLXGeometryCircle;
  @class FLXGeometryPolygon;
  @class FLXGeometryPath;

// server properties
extern NSString* FLXPostgresParameterServerVersion;
extern NSString* FLXPostgresParameterServerEncoding;
extern NSString* FLXPostgresParameterClientEncoding;
extern NSString* FLXPostgresParameterSuperUser;
extern NSString* FLXPostgresParameterSessionAuthorization;
extern NSString* FLXPostgresParameterDateStyle;
extern NSString* FLXPostgresParameterTimeZone;
extern NSString* FLXPostgresParameterIntegerDateTimes;
extern NSString* FLXPostgresParameterStandardConformingStrings;


#import "FLXPostgresTypes.h"
#import "FLXPostgresConnection.h"
#import "FLXPostgresConnection+Utils.h"
#import "FLXPostgresStatement.h"
#import "FLXPostgresResult.h"
#import "FLXPostgresException.h"

#import "FLXMacAddr.h"
#import "FLXTimeInterval.h"
#import "FLXPostgresArray.h"
#import "FLXGeometry.h"
