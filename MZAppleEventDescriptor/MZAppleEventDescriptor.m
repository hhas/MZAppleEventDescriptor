//
//  MZAppleEventDescriptor.m
//

#import "MZAppleEventDescriptor.h"


NSTimeInterval epochDelta = 35430.0 * 24 * 3600; // 1/1/1904 -> 1/1/2001


@implementation MZAppleEventDescriptor

// Create an autoreleased MZAppleEventDescriptor whose AEDesc type is typeNull.
+ (MZAppleEventDescriptor *)nullDescriptor {
    AEDesc aeDesc;
    AEInitializeDesc(&aeDesc);
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}

// Given some data, and a four-character type code, create and return an autoreleased MZAppleEventDescriptor that contains that data, with that type.
+ (nullable MZAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType bytes:(nullable const void *)bytes length:(NSUInteger)byteCount {
    return [[self alloc] initWithDescriptorType: descriptorType bytes: bytes length: byteCount];
}
+ (nullable MZAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType data:(nullable NSData *)data {
    return [[self alloc] initWithDescriptorType: descriptorType data: data];
}

// Given a value, create and return an autoreleased MZAppleEventDescriptor that contains that value, with an appropriate type (typeBoolean, typeEnumerated, typeSInt32, typeIEEE64BitFloatingPoint, or typeType, respectively).
+ (MZAppleEventDescriptor *)descriptorWithBoolean:(Boolean)boolean {
    AEDesc aeDesc;
    if (AECreateDesc((boolean ? typeTrue : typeFalse), NULL, 0, &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithEnumCode:(OSType)enumerator {
    AEDesc aeDesc;
    if (AECreateDesc(typeEnumeration, &enumerator, sizeof(enumerator), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithInt32:(SInt32)signedInt {
    AEDesc aeDesc;
    if (AECreateDesc(typeSInt32, &signedInt, sizeof(signedInt), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithDouble:(double)doubleValue {
    AEDesc aeDesc;
    if (AECreateDesc(typeIEEE64BitFloatingPoint, &doubleValue, sizeof(doubleValue), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithTypeCode:(OSType)typeCode {
    AEDesc aeDesc;
    if (AECreateDesc(typeType, &typeCode, sizeof(typeCode), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}

// Given a string, date, or file URL object, respectively, create and return an autoreleased MZAppleEventDescriptor that contains that value.
+ (MZAppleEventDescriptor *)descriptorWithString:(NSString *)string {
    // not too worried about efficiency for now
    if (!string) { return nil; }
    uint n = 1; // if typeUnicodeText then default to platform endianness; else use big-endian
    NSStringEncoding encoding = ((char)n) ? NSUTF16LittleEndianStringEncoding : NSUTF16BigEndianStringEncoding;
    NSUInteger size = [string maximumLengthOfBytesUsingEncoding: encoding];
    void *buffer = malloc(size);
    NSUInteger realSize;
    [string getBytes: buffer maxLength: size usedLength: &realSize
            encoding: encoding options: 0 range: NSMakeRange(0, size) remainingRange: nil];
    AEDesc aeDesc;
    OSErr err = AECreateDesc(typeUnicodeText, buffer, realSize, &aeDesc);
    free(buffer);
    if (err) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithDate:(NSDate *)date {
    SInt64 delta = (SInt64)([date timeIntervalSinceReferenceDate] - epochDelta); // caution: drops far dates on floor
    AEDesc aeDesc;
    if (AECreateDesc(typeLongDateTime, &delta, sizeof(delta), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithFileURL:(NSURL *)fileURL {
    if (!fileURL || !fileURL.isFileURL) { return nil; }
    NSString *string = fileURL.absoluteString;
    const char *buffer = string.UTF8String;
    NSUInteger size = [string lengthOfBytesUsingEncoding: NSUTF8StringEncoding] + 1;
    AEDesc aeDesc;
    if (AECreateDesc(typeFileURL, buffer, size, &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}

// Create and return an autoreleased event, list, or record MZAppleEventDescriptor, respectively.
+ (MZAppleEventDescriptor *)appleEventWithEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID
                                    targetDescriptor:(nullable MZAppleEventDescriptor *)targetDescriptor
                                            returnID:(AEReturnID)returnID transactionID:(AETransactionID)transactionID {
    return [[self alloc] initWithEventClass: eventClass eventID: eventID
                           targetDescriptor: targetDescriptor
                                   returnID: returnID transactionID: transactionID];
}
+ (MZAppleEventDescriptor *)listDescriptor {
    return [[self alloc] initListDescriptor];
}
+ (MZAppleEventDescriptor *)recordDescriptor {
    return [[self alloc] initRecordDescriptor];
}

// Create and return an autoreleased application address descriptor using the current process, a pid, a url referring to an application, or an application bundle identifier, respectively.  The result is suitable for use as the "targetDescriptor" parameter of +appleEventWithEventClass:/initWithEventClass:.
+ (MZAppleEventDescriptor *)currentProcessDescriptor {
    UInt32 process[2] = {0, kCurrentProcess};
    AEDesc aeDesc;
    if (AECreateDesc(typeProcessSerialNumber, &process, sizeof(process), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithProcessIdentifier:(pid_t)processIdentifier {
    AEDesc aeDesc;
    if (AECreateDesc(typeKernelProcessID, &processIdentifier, sizeof(processIdentifier), &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithBundleIdentifier:(NSString *)bundleIdentifier {
    if (!bundleIdentifier) { return nil; }
    const char *buffer = bundleIdentifier.UTF8String;
    NSUInteger size = [bundleIdentifier lengthOfBytesUsingEncoding: NSUTF8StringEncoding] + 1;
    AEDesc aeDesc;
    if (AECreateDesc(typeApplicationBundleID, buffer, size, &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}
+ (MZAppleEventDescriptor *)descriptorWithApplicationURL:(NSURL *)applicationURL {
    if (!applicationURL) { return nil; }
    NSString *string = applicationURL.absoluteString;
    const char *buffer = string.UTF8String;
    NSUInteger size = [string lengthOfBytesUsingEncoding: NSUTF8StringEncoding] + 1;
    AEDesc aeDesc;
    if (AECreateDesc(typeApplicationURL, buffer, size, &aeDesc)) { return nil; }
    return [[self alloc] initWithAEDescNoCopy: &aeDesc];
}

// The designated initializer.  The initialized object takes ownership of the passed-in AEDesc, and will call AEDisposeDesc() on it at deallocation time.
- (instancetype)initWithAEDescNoCopy:(const AEDesc *)aeDesc { // NS_DESIGNATED_INITIALIZER
    self = [super init];
    if (self) {
        _desc = *aeDesc;
        _owned = YES;
    }
    return self;
}
- (instancetype)init {
    AEDesc aeDesc;
    AEInitializeDesc(&aeDesc);
    return [self initWithAEDescNoCopy: &aeDesc];
}

- (void)dealloc {
    if (_owned) AEDisposeDesc(&_desc);
    // [super dealloc]; // TO DO: required in non-ARC
}

// Other initializers.
- (nullable instancetype)initWithDescriptorType:(DescType)descriptorType
                                          bytes:(nullable const void *)bytes length:(NSUInteger)byteCount {
    AEDesc aeDesc;
    if (AECreateDesc(descriptorType, bytes, byteCount, &aeDesc)) { return nil; }
    return [self initWithAEDescNoCopy: &aeDesc];
}
- (nullable instancetype)initWithDescriptorType:(DescType)descriptorType data:(nullable NSData *)data {
    AEDesc aeDesc;
    if (AECreateDesc(descriptorType, data.bytes, data.length, &aeDesc)) { return nil; }
    return [self initWithAEDescNoCopy: &aeDesc];
}
- (instancetype)initWithEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID targetDescriptor:(nullable MZAppleEventDescriptor *)targetDescriptor returnID:(AEReturnID)returnID transactionID:(AETransactionID)transactionID {
    AppleEvent aeDesc;
    // TO DO: is `target` argument nullable, or does it require null descriptor?
    if (AECreateAppleEvent(eventClass, eventID, targetDescriptor.aeDesc, returnID, transactionID, &aeDesc)) { return nil; }
    return [self initWithAEDescNoCopy: &aeDesc];
}
- (instancetype)initListDescriptor {
    AEDescList aeDesc;
    if (AECreateList(NULL, 0, false, &aeDesc)) { return nil; }
    return [self initWithAEDescNoCopy: &aeDesc];
}
- (instancetype)initRecordDescriptor {
    AEDescList aeDesc;
    if (AECreateList(NULL, 0, true, &aeDesc)) { return nil; }
    return [self initWithAEDescNoCopy: &aeDesc];
}

// Return a pointer to the AEDesc that is encapsulated by the object.
- (const AEDesc *)aeDesc { // NS_RETURNS_INNER_POINTER // @property (nullable, readonly)
    return &_desc;
}

// Get the four-character type code or the data from a fully-initialized descriptor.
- (DescType)descriptorType { // @property (readonly)
    return _desc.descriptorType;
}
- (NSData *)data { // @property (readonly, copy)
    NSUInteger size = AEGetDescDataSize(&_desc);
    void *buffer = malloc(size);
    if (AEGetDescData(&_desc, buffer, size)) {
        free(buffer);
        return nil;
    }
    return [NSData dataWithBytesNoCopy: buffer length: size freeWhenDone: YES];
}

// Return the contents of a descriptor, after coercing the descriptor's contents to typeBoolean, typeEnumerated, typeSInt32, typeIEEE64BitFloatingPoint, or typeType, respectively.
- (Boolean)booleanValue { // @property (readonly)
    Boolean result = false;
    OSErr err;
    switch (_desc.descriptorType) {
        case typeTrue:
            return true;
        case typeFalse:
            return false;
        case typeBoolean:
            err = AEGetDescData(&_desc, &result, sizeof(result));
            if (err) return 0;
            return result;
    }
    AEDesc aeDesc;
    err = AECoerceDesc(&_desc, typeBoolean, &aeDesc);
    if (err) return false; // ick; it is impossible to distinguish between a `false` result and coercion error
    switch (aeDesc.descriptorType) {
        case typeTrue:
            result = true;
            break;
        case typeFalse:
            result = false;
            break;
        case typeBoolean:
            err = AEGetDescData(&aeDesc, &result, sizeof(result));
            if (err) return 0;
    }
    AEDisposeDesc(&aeDesc);
    return result;
}
- (OSType)enumCodeValue { // @property (readonly)
    OSType result;
    OSErr err;
    if (_desc.descriptorType == typeEnumeration) { // assumes data handle is valid for desc type
        err = AEGetDescData(&_desc, &result, sizeof(result));
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeEnumeration, &aeDesc);
        if (err) return 0; // ditto
        err = AEGetDescData(&aeDesc, &result, sizeof(result));
        AEDisposeDesc(&aeDesc);
    }
    if (err) return 0; // ick; it is impossible to distinguish between a `0` result and coercion error
    return result;
}
- (SInt32)int32Value { // @property (readonly)
    SInt32 result;
    OSErr err;
    if (_desc.descriptorType == typeSInt32) { // assumes data handle is valid for desc type
        err = AEGetDescData(&_desc, &result, sizeof(result));
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeSInt32, &aeDesc);
        if (err) return 0;
        err = AEGetDescData(&aeDesc, &result, sizeof(result));
        AEDisposeDesc(&aeDesc);
    }
    if (err) return 0;
    return result;
}
- (double)doubleValue { // @property (readonly)
    double result;
    OSErr err;
    if (_desc.descriptorType == typeIEEE64BitFloatingPoint) { // assumes data handle is valid for desc type
        err = AEGetDescData(&_desc, &result, sizeof(result));
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeIEEE64BitFloatingPoint, &aeDesc);
        if (err) return 0;
        err = AEGetDescData(&aeDesc, &result, sizeof(result));
        AEDisposeDesc(&aeDesc);
    }
    if (err) return 0;
    return result;
}
- (OSType)typeCodeValue { // @property (readonly)
    OSType result;
    OSErr err;
    if (_desc.descriptorType == typeType) { // assumes data handle is valid for desc type
        err = AEGetDescData(&_desc, &result, sizeof(result));
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeType, &aeDesc);
        if (err) return 0; // ditto
        err = AEGetDescData(&aeDesc, &result, sizeof(result));
        AEDisposeDesc(&aeDesc);
    }
    if (err) return 0; // ad-nauseum
    return result;
}

// Return the contents of a descriptor, after coercing the descriptor's contents to a string, date, or file URL, respectively.
- (NSString *)stringValue { // @property (nullable, readonly, copy)
    NSStringEncoding encoding = 0;
    void *buffer;
    NSUInteger size;
    OSErr err;
    uint8_t bom[2];
    switch (_desc.descriptorType) {
        case typeUnicodeText: // native endian UTF16 with optional BOM // deprecated, but still in common use
        case typeUTF16ExternalRepresentation: // big-endian 16 bit unicode with optional byte-order-mark, or little-endian 16 bit unicode with required byte-order-mark
            if (AEGetDescDataSize(&_desc) >= sizeof(bom)) {
                err = AEGetDescData(&_desc, &bom, sizeof(bom));
                if (err) return nil;
                if (bom[0] == 0xFE && bom[1] == 0xFF) {
                    encoding = NSUTF16BigEndianStringEncoding;
                } else if (bom[0] == 0xFF && bom[1] == 0xFE) {
                    encoding = NSUTF16LittleEndianStringEncoding;
                } else { // no BOM found
                    uint n = 1; // if typeUnicodeText then default to platform endianness; else use big-endian
                    encoding = (_desc.descriptorType == typeUnicodeText && (char)n) ? NSUTF16LittleEndianStringEncoding
                                                                                    : NSUTF16BigEndianStringEncoding;
                }
            }
            break;
        case typeUTF8Text:
            encoding = NSUTF8StringEncoding;
            break;
    }
    if (encoding) {
        size = AEGetDescDataSize(&_desc);
        buffer = malloc(size);
        err = AEGetDescData(&_desc, buffer, size);
    } else {
        AEDesc aeDesc;
        encoding = NSUTF8StringEncoding;
        err = AECoerceDesc(&_desc, typeUTF8Text, &aeDesc);
        if (err) return nil;
        size = AEGetDescDataSize(&aeDesc);
        buffer = malloc(size);
        err = AEGetDescData(&aeDesc, buffer, size);
        AEDisposeDesc(&aeDesc);
    }
    if (err) {
        free(buffer);
        return nil;
    }
    printf("BUFF: |%s|\n", buffer);
    return [[NSString alloc] initWithBytesNoCopy: buffer length: size encoding: encoding freeWhenDone: YES];
}
- (NSDate *)dateValue { // @property (nullable, readonly, copy)
    SInt64 result;
    OSErr err;
    if (_desc.descriptorType == typeLongDateTime) {
        err = AEGetDescData(&_desc, &result, sizeof(result));
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeLongDateTime, &aeDesc);
        if (err) return nil;
        err = AEGetDescData(&aeDesc, &result, sizeof(result));
        AEDisposeDesc(&aeDesc);
    }
    if (err) return nil;
    return [NSDate dateWithTimeIntervalSinceReferenceDate: result + epochDelta];
}
- (NSURL *)fileURLValue { // @property (nullable, readonly, copy)
    char *buffer;
    NSUInteger size;
    OSErr err;
    if (_desc.descriptorType == typeFileURL) {
        size = AEGetDescDataSize(&_desc);
        buffer = malloc(size);
        err = AEGetDescData(&_desc, buffer, size);
    } else {
        AEDesc aeDesc;
        err = AECoerceDesc(&_desc, typeFileURL, &aeDesc);
        if (err) return nil;
        size = AEGetDescDataSize(&aeDesc);
        buffer = malloc(size);
        err = AEGetDescData(&aeDesc, buffer, size);
        AEDisposeDesc(&aeDesc);
    }
    if (err) {
        free(buffer);
        return nil;
    }
    NSURL *result = [NSURL fileURLWithFileSystemRepresentation: buffer isDirectory: NO relativeToURL: nil];
    free(buffer);
    return result;
}

// Accessors for an event descriptor.
- (AEEventClass)eventClass { // @property (readonly)
    OSType result, typeCode;
    Size actualSize;
    if (AEGetAttributePtr(&_desc, keyAEEventClass, typeType, &typeCode, &result, sizeof(result), &actualSize)) { return 0; }
    return result;
}
- (AEEventID)eventID { // @property (readonly)
    OSType result, typeCode;
    Size actualSize;
    if (AEGetAttributePtr(&_desc, keyAEEventID, typeType, &typeCode, &result, sizeof(result), &actualSize)) { return 0; }
    return result;
}
- (AEReturnID)returnID { // @property (readonly)
    SInt16 result;
    OSType typeCode;
    Size actualSize;
    if (AEGetAttributePtr(&_desc, keyAEEventID, typeSInt16, &typeCode, &result, sizeof(result), &actualSize)) { return 0; }
    return result;
}
- (AETransactionID)transactionID { // @property (readonly)
    SInt32 result;
    OSType typeCode;
    Size actualSize;
    if (AEGetAttributePtr(&_desc, keyAEEventID, typeSInt32, &typeCode, &result, sizeof(result), &actualSize)) { return 0; }
    return result;
}

// Set, retrieve, or remove parameter descriptors inside an event descriptor.
- (void)setParamDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword {
    AEPutParamDesc(&_desc, keyword, descriptor.aeDesc);
}
- (nullable MZAppleEventDescriptor *)paramDescriptorForKeyword:(AEKeyword)keyword {
    AEDesc result;
    if (AEGetParamDesc(&_desc, keyword, typeWildCard, &result)) { return nil; }
    return [[self.class alloc] initWithAEDescNoCopy: &result];
}
- (void)removeParamDescriptorWithKeyword:(AEKeyword)keyword {
    AEDeleteParam(&_desc, keyword);
}

// Set or retrieve attribute descriptors inside an event descriptor.
- (void)setAttributeDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword {
    AEPutAttributeDesc(&_desc, keyword, descriptor.aeDesc);
}
- (nullable MZAppleEventDescriptor *)attributeDescriptorForKeyword:(AEKeyword)keyword {
    AEDesc result;
    if (AEGetAttributeDesc(&_desc, keyword, typeWildCard, &result)) { return nil; }
    return [[self.class alloc] initWithAEDescNoCopy: &result];
}

// Send an Apple event.
- (nullable MZAppleEventDescriptor *)sendEventWithOptions:(NSAppleEventSendOptions)sendOptions
                                                  timeout:(NSTimeInterval)timeoutInSeconds error:(NSError **)error {
    if (error) { *error = nil; }
    AEDesc result = {typeNull, NULL};
    OSErr err = AESendMessage(&_desc, &result, sendOptions, (timeoutInSeconds > 0 ? timeoutInSeconds * 60 : timeoutInSeconds));
    if (err) {
        if (*error) {
            *error = [NSError errorWithDomain: @"NSOSStatusErrorDomain" code: err userInfo: @{}]; // TO DO: other error info
        }
        return nil;
    }
    return [[self.class alloc] initWithAEDescNoCopy: &result];
}

// Return whether or not a descriptor is a record-like descriptor.  Record-like descriptors function as records, but may have a descriptorType other than typeAERecord, such as typeObjectSpecifier.
- (BOOL)isRecordDescriptor { // @property (readonly)
    return AECheckIsRecord(&_desc);
}

// Return the number of items inside a list or record descriptor.
- (NSInteger)numberOfItems { // @property (readonly)
    long result;
    if (AECountItems(&_desc, &result)) { return 0; }
    return (NSInteger)result;
}

// Set, retrieve, or remove indexed descriptors inside a list or record descriptor.
- (void)insertDescriptor:(MZAppleEventDescriptor *)descriptor atIndex:(NSInteger)index {
    AEPutDesc(&_desc, (long)index, descriptor.aeDesc);
}
- (nullable MZAppleEventDescriptor *)descriptorAtIndex:(NSInteger)index {
    AEKeyword keyword;
    AEDesc result;
    if (AEGetNthDesc(&_desc, (long)index, typeWildCard, &keyword, &result)) { return nil; }
    return [[self.class alloc] initWithAEDescNoCopy: &result];
}
- (void)removeDescriptorAtIndex:(NSInteger)index {
    AEDeleteItem(&_desc, (long)index);
}

// Set, retrieve, or remove keyed descriptors inside a record descriptor.
- (void)setDescriptor:(MZAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword {
    AEPutParamDesc(&_desc, keyword, descriptor.aeDesc);
}
- (nullable MZAppleEventDescriptor *)descriptorForKeyword:(AEKeyword)keyword {
    AEDesc result;
    if (AEGetParamDesc(&_desc, keyword, typeWildCard, &result)) { return nil; }
    return [[self.class alloc] initWithAEDescNoCopy: &result];
}
- (void)removeDescriptorWithKeyword:(AEKeyword)keyword {
    AEDeleteParam(&_desc, keyword);
}

// Return the keyword associated with an indexed descriptor inside a record descriptor.
- (AEKeyword)keywordForDescriptorAtIndex:(NSInteger)index {
    AEKeyword result = 0;
    OSType typeCode;
    char buffer;
    Size actualSize;
    AEGetNthPtr(&_desc, (long)index, typeWildCard, &result, &typeCode, &buffer, 1, &actualSize);
    return result;
}

// Create and return a descriptor of the requested type, doing a coercion if that's appropriate and possible.
- (nullable MZAppleEventDescriptor *)coerceToDescriptorType:(DescType)descriptorType {
    AEDesc aeDesc;
    if(AECoerceDesc(&_desc, descriptorType, &aeDesc)) { return nil; }
    return [[self.class alloc] initWithAEDescNoCopy: &aeDesc];
}

- (NSString *)description { // (may not work in Marzipan)
    Handle h;
    AEPrintDescToHandle(&_desc, &h); // should be deprecated
    NSString *result = [NSString stringWithFormat: @"<MZAppleEventDescriptor %s>", *h];
    // DisposeHandle(h); // TO DO: not in iOS; deprecated in macOS
    return result;
}

@end
