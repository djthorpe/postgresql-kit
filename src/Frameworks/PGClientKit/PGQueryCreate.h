

////////////////////////////////////////////////////////////////////////////////
// create statements


////////////////////////////////////////////////////////////////////////////////
// drop statements

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The name of the table or view
 */
@property NSString* table;

/**
 *  The name of the schema
 */
@property NSString* schema;

/**
 *  The name of the database
 */
@property NSString* database;

/**
 *  The name of the role
 */
@property NSString* role;

/**
 *  The owner for the database or role
 */
@property NSString* owner;

/**
 *  The template to use when creating a database
 */
@property NSString* template;

/**
 *  The character encoding to use when creating a database
 */
@property NSString* encoding;

/**
 *  The tablespace for the database and/or table
 */
@property NSString* tablespace;

/**
 *  The password to use when creating a role (will automatically be encrypted)
 */
@property NSString* password;

/**
 *  The connection limit to set when creating a database or role. By default,
 *  it is set to -1 which means no connection limit
 */
@property NSInteger connectionLimit;

/**
 *  The expiry date to set for role login, when creating roles. Can be set
 *  to nil which indicates no expiry limit.
 */
@property NSDate* expiry;

@end
