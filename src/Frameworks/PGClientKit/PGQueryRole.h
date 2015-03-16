
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

@interface PGQueryRole : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create a query to create a role/user for the connected server
 *
 *  @param role     The name of the role/user to create
 *  @param options  Option flags:
 *                    * `PGQueryOptionRolePrivSuperuser` should be used to make the role a superuser.
 *                    * `PGQueryOptionRolePrivCreateDatabase`should be used to allow the role to create databases.
 *                    * `PGQueryOptionRolePrivCreateRole` should be used if the role should be allowed to create roles.
 *                    * `PGQueryOptionRolePrivInherit` should be used to inherit options from the role parent.
 *                    * `PGQueryOptionRolePrivLogin` should be used to allow the role to login as a user.
 *                    * `PGQueryOptionSetConnectionLimit` should be used to set a connection limit for the user.
 *                    * TODO
 *
 *  @return Returns the PGQueryRole object, or nil if the query could not be created.
 */
+(PGQueryRole* )create:(NSString* )role options:(NSUInteger)options;


/**
 *  Create a query to drop a role from the currently connected server
 *
 *  @param role     The name of the role to drop
 *  @param options  Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                  the operation should be silently ignored if the role
 *                  does not exist.
 *
 *  @return Returns the PGQueryRole object, or nil if the query could not be created.
 */
+(PGQueryRole* )drop:(NSString* )role options:(NSUInteger)options;

/**
 *  Create a query to rename a role to a new name
 *
 *  @param role The existing role name to change, cannot be nil or empty
 *  @param name The new role name, cannot be nil or empty
 *
 *  @return Returns the PGQueryRole object, or nil if the query could not be created.
 */
+(PGQueryRole* )alter:(NSString* )role name:(NSString* )name;

/**
 *  Create a query to change the options for a role
 *
 *  @return Returns the PGQueryRole object, or nil if the query could not be created.
 */
+(PGQueryRole* )listWithOptions:(NSUInteger)options;


////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the name of the role
 */
@property (readonly) NSString* role;

/**
 *  Return the new name of the dabase when renaming
 */
@property (readonly) NSString* name;

/**
 *  The parent role owner for the role
 */
@property NSString* owner;

/**
 *  The connection limit to set when creating a database or role. By default,
 *  it is set to -1 which means no connection limit
 */
@property NSInteger connectionLimit;

/**
 *  The password to use when creating a role (will automatically be encrypted)
 */
@property NSString* password;

/**
 *  The expiry date to set for role login, when creating roles. Can be set
 *  to nil which indicates no expiry limit.
 */
@property NSDate* expiry;

@end
