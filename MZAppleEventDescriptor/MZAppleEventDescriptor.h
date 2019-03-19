//
//  MZAppleEventDescriptor.h
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface MZAppleEventDescriptor : NSObject { // <NSCopying, NSSecureCoding> {
@private
    AEDesc _desc;
@public
    BOOL _owned;
 //   BOOL _hasValidDesc;
 //   char _padding[3];
}

// Create an autoreleased MZAppleEventDescriptor whose AEDesc type is typeNull.
+ (MZAppleEventDescriptor *)nullDescriptor;

// Given some data, and a four-character type code, create and return an autoreleased MZAppleEventDescriptor that contains that data, with that type.
+ (nullable MZAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType bytes:(nullable const void *)bytes length:(NSUInteger)byteCount;
+ (nullable MZAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType data:(nullable NSData *)data;

// Given a value, create and return an autoreleased MZAppleEventDescriptor that contains that value, with an appropriate type (typeBoolean, typeEnumerated, typeSInt32, typeIEEE64BitFloatingPoint, or typeType, respectively).
+ (MZAppleEventDescriptor *)descriptorWithBoolean:(Boolean)boolean;
+ (MZAppleEventDescriptor *)descriptorWithEnumCode:(OSType)enumerator;
+ (MZAppleEventDescriptor *)descriptorWithInt32:(SInt32)signedInt;
+ (MZAppleEventDescriptor *)descriptorWithDouble:(double)doubleValue API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
+ (MZAppleEventDescriptor *)descriptorWithTypeCode:(OSType)typeCode;

// Given a string, date, or file URL object, respectively, create and return an autoreleased MZAppleEventDescriptor that contains that value.
+ (MZAppleEventDescriptor *)descriptorWithString:(NSString *)string;
+ (MZAppleEventDescriptor *)descriptorWithDate:(NSDate *)date API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
+ (MZAppleEventDescriptor *)descriptorWithFileURL:(NSURL *)fileURL API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);

// Create and return an autoreleased event, list, or record MZAppleEventDescriptor, respectively.
+ (MZAppleEventDescriptor *)appleEventWithEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID targetDescriptor:(nullable MZAppleEventDescriptor *)targetDescriptor returnID:(AEReturnID)returnID transactionID:(AETransactionID)transactionID;
+ (MZAppleEventDescriptor *)listDescriptor;
+ (MZAppleEventDescriptor *)recordDescriptor;

// Create and return an autoreleased application address descriptor using the current process, a pid, a url referring to an application, or an application bundle identifier, respectively.  The result is suitable for use as the "targetDescriptor" parameter of +appleEventWithEventClass:/initWithEventClass:.
+ (MZAppleEventDescriptor *)currentProcessDescriptor API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
+ (MZAppleEventDescriptor *)descriptorWithProcessIdentifier:(pid_t)processIdentifier API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
+ (MZAppleEventDescriptor *)descriptorWithBundleIdentifier:(NSString *)bundleIdentifier API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
+ (MZAppleEventDescriptor *)descriptorWithApplicationURL:(NSURL *)applicationURL API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);

// The designated initializer.  The initialized object takes ownership of the passed-in AEDesc, and will call AEDisposeDesc() on it at deallocation time.
- (instancetype)initWithAEDescNoCopy:(const AEDesc *)aeDesc NS_DESIGNATED_INITIALIZER;

// Other initializers.
- (nullable instancetype)initWithDescriptorType:(DescType)descriptorType bytes:(nullable const void *)bytes length:(NSUInteger)byteCount;
- (nullable instancetype)initWithDescriptorType:(DescType)descriptorType data:(nullable NSData *)data;
- (instancetype)initWithEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID targetDescriptor:(nullable MZAppleEventDescriptor *)targetDescriptor returnID:(AEReturnID)returnID transactionID:(AETransactionID)transactionID;
- (instancetype)initListDescriptor;
- (instancetype)initRecordDescriptor;

// Return a pointer to the AEDesc that is encapsulated by the object.
@property (nullable, readonly) const AEDesc *aeDesc NS_RETURNS_INNER_POINTER;

// Get the four-character type code or the data from a fully-initialized descriptor.
@property (readonly) DescType descriptorType;
@property (readonly, copy) NSData *data;

// Return the contents of a descriptor, after coercing the descriptor's contents to typeBoolean, typeEnumerated, typeSInt32, typeIEEE64BitFloatingPoint, or typeType, respectively.
@property (readonly) Boolean booleanValue;
@property (readonly) OSType enumCodeValue;
@property (readonly) SInt32 int32Value;
@property (readonly) double doubleValue API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
@property (readonly) OSType typeCodeValue;

// Return the contents of a descriptor, after coercing the descriptor's contents to a string, date, or file URL, respectively.
@property (nullable, readonly, copy) NSString *stringValue;
@property (nullable, readonly, copy) NSDate *dateValue API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
@property (nullable, readonly, copy) NSURL *fileURLValue API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);

// Accessors for an event descriptor.
@property (readonly) AEEventClass eventClass;
@property (readonly) AEEventID eventID;
@property (readonly) AEReturnID returnID;
@property (readonly) AETransactionID transactionID;

// Set, retrieve, or remove parameter descriptors inside an event descriptor.
- (void)setParamDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword;
- (nullable MZAppleEventDescriptor *)paramDescriptorForKeyword:(AEKeyword)keyword;
- (void)removeParamDescriptorWithKeyword:(AEKeyword)keyword;

// Set or retrieve attribute descriptors inside an event descriptor.
- (void)setAttributeDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword;
- (nullable MZAppleEventDescriptor *)attributeDescriptorForKeyword:(AEKeyword)keyword;

// Send an Apple event.
- (nullable MZAppleEventDescriptor *)sendEventWithOptions:(NSAppleEventSendOptions)sendOptions timeout:(NSTimeInterval)timeoutInSeconds error:(NSError **)error API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);

// Return whether or not a descriptor is a record-like descriptor.  Record-like descriptors function as records, but may have a descriptorType other than typeAERecord, such as typeObjectSpecifier.
@property (readonly) BOOL isRecordDescriptor API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);

// Return the number of items inside a list or record descriptor.
@property (readonly) NSInteger numberOfItems;

// Set, retrieve, or remove indexed descriptors inside a list or record descriptor.
- (void)insertDescriptor:(MZAppleEventDescriptor *)descriptor atIndex:(NSInteger)index;
- (nullable MZAppleEventDescriptor *)descriptorAtIndex:(NSInteger)index;
- (void)removeDescriptorAtIndex:(NSInteger)index;

// Set, retrieve, or remove keyed descriptors inside a record descriptor.
- (void)setDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword;
- (nullable MZAppleEventDescriptor *)descriptorForKeyword:(AEKeyword)keyword;
- (void)removeDescriptorWithKeyword:(AEKeyword)keyword;

// Return the keyword associated with an indexed descriptor inside a record descriptor.
- (AEKeyword)keywordForDescriptorAtIndex:(NSInteger)index;

// Create and return a descriptor of the requested type, doing a coercion if that's appropriate and possible.
- (nullable MZAppleEventDescriptor *)coerceToDescriptorType:(DescType)descriptorType;

@end


NS_ASSUME_NONNULL_END
