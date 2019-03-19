//
//  MZAppleEventConverter.h
//

// TO DO: this class is simplified copy of AEMCodecs from AppleEventBridge; it is not ideal for server-side use as a well-designed AE API should coerce supplied parameters to the expected AE type(s) *before* unpacking them (or returning coercion error), whereas this unpacks parameters directly to their corresponding Cocoa class and leaves application code to typecheck/convert those itself; a better approach is that used by SwiftAutomation, where the expected type is described using the native type system, e.g. `try unpack(desc) as Array<Int>` ensures the supplied descriptor is unpacked as a list of integers or not at all


//  Standard class for packing/unpacking Cocoa and AEMQuery instances;
//  also provides base class for high-level wrappers
//
// TO DO: implement -pack:, -unpack: as convenience shortcuts

#import <Foundation/Foundation.h>
#import "MZAppleEventDescriptor.h"
#import "MZFourCharCode.h"


/**********************************************************************/

@interface MZAppleEventConverter : NSObject

+ (instancetype)defaultCodecs;

/**********************************************************************/
// main pack methods

/*
 * Converts a Cocoa object to an MZAppleEventDescriptor.
 * Calls -packUnknown: if object is of an unsupported class.
 */
//- (MZAppleEventDescriptor *)pack:(id)anObject;

- (MZAppleEventDescriptor *)pack:(id)anObject error:(NSError * __autoreleasing *)error;

/*
 * Called by -pack:error: to process a Cocoa object of unsupported class.
 * Default implementation returns nil and NSError; subclasses can
 * override this method to provide alternative behaviours if desired.
 */
- (MZAppleEventDescriptor *)packUnknown:(id)anObject error:(NSError * __autoreleasing *)error;


/**********************************************************************/
/*
 * The following methods will be called by -pack:error: as needed.
 * Subclasses can override the following methods to provide alternative 
 * behaviours if desired, although this is generally unnecessary.
 */
- (MZAppleEventDescriptor *)packArray:(NSArray *)anObject error:(NSError * __autoreleasing *)error;
- (MZAppleEventDescriptor *)packDictionary:(NSDictionary *)anObject error:(NSError * __autoreleasing *)error;


/**********************************************************************/
// main unpack methods; subclasses can override to process still-unconverted objects

/*
 * Converts an MZAppleEventDescriptor to a Cocoa object.
 * Calls -unpackUnknown: if descriptor is of an unsupported type.
 */
//- (id)unpack:(MZAppleEventDescriptor *)desc;

- (id)unpack:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;

/*
 * Called by -unpack: to process an MZAppleEventDescriptor of unsupported type.
 * Default implementation checks to see if the descriptor is a record-type structure
 * and unpacks it as an NSDictionary if it is, otherwise it returns the value as-is.
 * Subclasses can override this method to provide alternative behaviours if desired.
 */
- (id)unpackUnknown:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;


/**********************************************************************/
/*
 * The following methods will be called by -unpack: as needed.
 * Subclasses can override the following methods to provide alternative 
 * behaviours if desired, although this is generally unnecessary.
 */
- (id)unpackAEList:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackAERecord:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackAERecordKey:(AEKeyword)key error:(NSError * __autoreleasing *)error;

- (id)unpackType:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackEnum:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackProperty:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackKeyword:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;

- (id)unpackObjectSpecifier:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackInsertionLoc:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;

- (id)app;
- (id)con;
- (id)its;
- (id)customRoot:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;

- (id)unpackCompDescriptor:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;
- (id)unpackLogicalDescriptor:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error;

/*
 * Notes:
 *
 * kAEContains is also used to construct 'is in' tests, where test value is first operand
 * and specifier being tested is second operand, so need to make sure first operand is an
 * its-based ref; if not, rearrange accordingly.
 *
 * Since type-checking is involved, this extra hook is provided so that AEBridge's
 * AEBAppData subclasses can override this method to add its own type checking.
 */
- (id)unpackContainsCompDescriptorWithOperand1:(id)op1 operand2:(id)op2 error:(NSError * __autoreleasing *)error;

@end
