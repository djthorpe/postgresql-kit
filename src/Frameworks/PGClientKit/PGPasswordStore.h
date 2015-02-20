
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

/**
 *  PGPasswordStore is used to store passwords temporarily in memory, keyed by
 *  URL. Optionally, the password can also be stored encyrpted within the
 *  users' keychain.
 */

@interface PGPasswordStore : NSObject {
	NSMutableDictionary* _store;
}

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Returns the service name for the kaychain entry. In general, this will be 
 *  set to "pgsql". It's currently read-only but in future this could be made
 *  a custom property to be set when the instance is created
 */
@property (readonly) NSString* serviceName;

////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  Return a stored password for a URL, or nil if no password was stored 
 *  against that URL, either from the current set of passwords, or from the 
 *  keychain.
 *
 *  @param url The PostgreSQL connection URL
 *
 *  @return Returns the password in plaintext, or nil if no password could be 
 *          located or the URL was malformed
 */
-(NSString* )passwordForURL:(NSURL* )url;

/**
 *  Return a stored password for a URL, or nil if no password was stored 
 *  against that URL, either from the current set of passwords, or from the 
 *  keychain.
 *
 *  @param url   The PostgreSQL connection URL
 *  @param error Pointer to an error object, which will contain an error 
 *               condition if nil is returned
 *
 *  @return Returns the password in plaintext, or nil if no password could be 
 *          located or the URL was malformed
 */
-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error;

/**
 *  Return a stored password for a URL, or nil if no password was stored 
 *  against that URL, either from the current set of passwords, or optionally
 *  from the keychain.
 *
 *  @param url              The PostgreSQL connection URL
 *  @param readFromKeychain Indicate YES if the keychain should be checked
 *  @param error            Pointer to an error object, which will contain an
 *                          error condition if nil is returned
 *
 *  @return Returns the password in plaintext, or nil if no password could be 
 *          located
 */
-(NSString* )passwordForURL:(NSURL* )url readFromKeychain:(BOOL)readFromKeychain error:(NSError** )error;

/**
 *  Set password for a particular PostgreSQL URL, and optionally store 
 *  permanently to the users' keychain.
 *
 *  @param password       The plaintext password
 *  @param url            The PostgreSQL connection URL
 *  @param saveToKeychain Indicate YES if the password should also be stored in
 *                        the users' keychain
 *
 *  @return Returns NO if the password could not be stored, due to malformed URL
 */
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain;

/**
 *  Set password for a particular PostgreSQL URL, and optionally store 
 *  permanently to the users' keychain.
 *
 *  @param password       The plaintext password
 *  @param url            The PostgreSQL connection URL
 *  @param saveToKeychain Indicate YES if the password should also be stored in
 *                        the users' keychain
 *  @param error          Pointer to an error object, which will contain an
 *                        error condition if NO is returned
 *
 *  @return Returns NO if the password could not be stored, due to malformed URL
 */
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError** )error;

@end

