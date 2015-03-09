
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

enum {
	PGCSVImporterHasHeader          = 0x00000001, // use line 0 as the headings
	PGCSVImporterIgnoreHashComments = 0x00000002, // ignore lines starting with #
	PGCSVImporterIgnoreCodeComments = 0x00000004, // ignore lines starting with //
	PGCSVImporterIgnoreComments     = 0x00000006, // ignore lines starting with # or //
};

////////////////////////////////////////////////////////////////////////////////

// forward class declarations
@class PGCSVImporter;
@class PGTableModel;

// header includes
#import "PGCSVImporter.h"
#import "PGTableModel.h"

