//
//  MZAppleEventConverter.m
//

#import "MZAppleEventConverter.h"

//
// Note: MZAppleEventDescriptors are not hashable so don't work as dictionary keys; when packing AERecords, MZFourCharCode is used instead (or NSString when unpacking 'usrf' item containing user-defined names).
//

// TO DO: make sure that mapping typeBoolean/typeTrue/typeFalse to NSNumber/@YES/@NO always uses __NSCFBoolean as its internal representation


/**********************************************************************/


@implementation MZAppleEventConverter

+ (instancetype)defaultCodecs {
    static dispatch_once_t pred = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}


/***********************************/
// main pack methods; subclasses can override to process some or all values themselves


- (MZAppleEventDescriptor *)pack:(id)anObject error:(NSError * __autoreleasing *)error {
    UInt32 uint32;
    SInt64 sint64;
    UInt64 uint64;
    MZAppleEventDescriptor *result = nil;
    
    if (error) *error = nil;
 //   if ([anObject conformsToProtocol: @protocol(MZSelfPackingProtocol)]) {
 //       result = [anObject packWithCodecs: self error: error];
   // } else
    if ([anObject isKindOfClass: NSNumber.class]) {
        if (CFBooleanGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(anObject))) {
            result = [MZAppleEventDescriptor descriptorWithBoolean: [anObject boolValue]];
        } else {
            switch (*[anObject objCType]) {
                    /*
                     * note: for better compatibility with less well-designed applications that don't like
                     * less common integer types (typeSInt64, typeUInt32, etc.), try to use typeSInt32
                     * and typeIEEE64BitFloatingPoint (double) whenever possible
                     */
                case 'b':
                case 'c':
                case 'C':
                case 's':
                case 'S':
                case 'i':
                case 'l': // TO DO: check this is always SInt32
                packAsSInt32:
                    result = [MZAppleEventDescriptor descriptorWithInt32: [anObject intValue]];
                    break;
                case 'I':
                case 'L': // TO DO: check this is always UInt32
                    uint32 = [anObject unsignedIntValue];
                    if (uint32 < 0x7FFFFFFF) {
                        goto packAsSInt32;
                    }
                    result = [MZAppleEventDescriptor descriptorWithDescriptorType: typeUInt32
                                                                            bytes: &uint32
                                                                           length: sizeof(uint32)];
                    break;
                case 'q':
                packAsSInt64:
                    sint64 = [anObject longLongValue];
                    if (sint64 >= 0x80000000 && sint64 < 0x7FFFFFFF) {
                        goto packAsSInt32;
                    }
                    result = [MZAppleEventDescriptor descriptorWithDescriptorType: typeSInt64
                                                                            bytes: &sint64
                                                                           length: sizeof(sint64)];
                    break;
                case 'Q':
                    uint64 = [anObject unsignedLongLongValue];
                    if (uint64 < 0x7FFFFFFF) {
                        goto packAsSInt32;
                    } else if (uint64 < pow(2, 63)) {
                        goto packAsSInt64;
                    }
                    // caution: 64-bit [u]ints may not be supported by all clients
                    result = [MZAppleEventDescriptor descriptorWithDescriptorType: 'ucom'
                                                                            bytes: &uint64
                                                                           length: sizeof(uint64)];
                    break;
                default: // f, d
                    result = [MZAppleEventDescriptor descriptorWithDouble: [anObject doubleValue]];
            }
        }
    } else if ([anObject isKindOfClass: NSString.class]) {
        result = [MZAppleEventDescriptor descriptorWithString: anObject];
    } else if ([anObject isKindOfClass: NSDate.class]) {
        result = [MZAppleEventDescriptor descriptorWithDate: anObject];
    } else if ([anObject isKindOfClass: NSArray.class]) {
        result = [self packArray: anObject error: error];
    } else if ([anObject isKindOfClass: NSDictionary.class]){
        result = [self packDictionary: anObject error: error];
    } else if ([anObject isKindOfClass: NSURL.class] && [anObject isFileURL]) {
        result = [MZAppleEventDescriptor descriptorWithFileURL: anObject];
    } else if ([anObject isKindOfClass: MZAppleEventDescriptor.class]) {
        result = anObject;
    } else if ([anObject isKindOfClass: NSNull.class]) {
        result = [MZAppleEventDescriptor nullDescriptor];
    } else {
        result = [self packUnknown: anObject error: error];
    }
    return result;
}

// subclasses can override -packUnknown: to process any still-unconverted types
- (MZAppleEventDescriptor *)packUnknown:(id)anObject error:(NSError * __autoreleasing *)error {
    if (error) *error = [NSError errorWithDomain: @"NSOSStatusErrorDomain" code: errAECoercionFail userInfo: nil];
    return nil;
}


// methods called by -pack:error:; may be overridden by subclasses to modify how values are packed

- (MZAppleEventDescriptor *)packArray:(NSArray *)anObject error:(NSError * __autoreleasing *)error {
    MZAppleEventDescriptor *arrayDesc = [MZAppleEventDescriptor listDescriptor];
    for (id item in anObject) {
        MZAppleEventDescriptor *desc = [self pack: item error: error];
        if (!desc) return nil; // TO DO: provide better error message describing array
        [arrayDesc insertDescriptor: desc atIndex: 0];
    }
    return arrayDesc;
}


- (MZAppleEventDescriptor *)packDictionary:(NSDictionary *)anObject error:(NSError * __autoreleasing *)error {
    MZAppleEventDescriptor *result, *coercedDesc, *keyDesc, *valueDesc, *userProperties = nil;
    result = [MZAppleEventDescriptor recordDescriptor];
    for (id key in anObject) {
        id value = anObject[key];
        if (!value) { // bad key
            if (error) *error = [NSError errorWithDomain: @"NSOSStatusErrorDomain" code: errAECoercionFail userInfo: nil];
            return nil;
        }
        if (!(keyDesc = [self pack: key error: error])) return nil;
        if (!(valueDesc = [self pack: value error: error])) return nil;
        OSType keyCode = [keyDesc descriptorType];
        if (keyCode == typeType || keyCode == typeProperty) {
            keyCode = [keyDesc typeCodeValue];
            if (keyCode == pClass && [valueDesc descriptorType] == typeType) {
                // AppleScript packs records that contain a 'class' property by coercing the record to that type
                coercedDesc = [result coerceToDescriptorType: [valueDesc typeCodeValue]];
                if (coercedDesc) {
                    result = coercedDesc;
                } else { // coercion failed, so pack it as a regular record item instead
                    [result setDescriptor: valueDesc forKeyword: keyCode];
                }
            } else {
                [result setDescriptor: valueDesc forKeyword: keyCode];
            }
        } else {
            if (!userProperties) userProperties = [MZAppleEventDescriptor listDescriptor];
            [userProperties insertDescriptor: keyDesc atIndex: 0]; // i.e. with 1-indexed AEDescs, index 0 = 'append'
            [userProperties insertDescriptor: valueDesc atIndex: 0];
        }
    }
    if (userProperties) [result setDescriptor: userProperties forKeyword: 'usrf'];
    return result;
}


- (MZAppleEventDescriptor *)applicationRootDescriptor {
    return [MZAppleEventDescriptor nullDescriptor];
}


/***********************************/
// main unpack methods; subclasses can override to process some or all descs themselves

//- (id)unpack:(MZAppleEventDescriptor *)desc {
//}


- (id)unpack:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    unsigned short uint16;
    SInt16 sint16;
    UInt32 uint32;
    SInt64 sint64;
    unsigned long long uint64;
    float float32;
    short qdPoint[2];
    short qdRect[4];
    unsigned short rgbColor[3];
    id result = nil;
    if (error) *error = nil;
    switch (desc.descriptorType) {
        case typeObjectSpecifier:
            result = [self unpackObjectSpecifier: desc error: error];
            break;
        case typeSInt32:
            result = @(desc.int32Value);
            break;
        case typeIEEE64BitFloatingPoint:
            result = @(desc.doubleValue);
            break;
        case typeChar:
        case typeIntlText:
        case typeUTF8Text:
        case typeUTF16ExternalRepresentation:
        case typeStyledText:
        case typeUnicodeText:
        case typeVersion:
            result = desc.stringValue;
            break;
        case typeFalse:
        case typeTrue:
        case typeBoolean:
            result = desc.booleanValue ? @YES : @NO; // this assumes Cocoa will always represent @YES and @NO as __NSCFBoolean
            break;
        case typeLongDateTime:
            result = desc.dateValue;
            break;
        case typeAEList:
            result = [self unpackAEList: desc error: error];
            break;
        case typeAERecord:
            result = [self unpackAERecord: desc error: error];
            break;
        case typeAlias:
        case typeBookmarkData:
        case typeFileURL:
        case typeFSRef:
        {
            NSData *data = [desc coerceToDescriptorType: typeFileURL].data;
            if (data) {
                NSString *path = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                if (path) {
                    result = [NSURL fileURLWithPath: path];
                }
            }
            break;
        }
        case typeType:
            result = [self unpackType: desc error: error];
            break;
        case typeEnumerated:
            result = [self unpackEnum: desc error: error];
            break;
        case typeProperty:
            result = [self unpackProperty: desc error: error];
            break;
        case typeKeyword:
            result = [self unpackKeyword: desc error: error];
            break;
        case typeSInt16:
            [desc.data getBytes: &sint16 length: sizeof(sint16)];
            result = @(sint16);
            break;
        case typeUInt16:
            [desc.data getBytes: &uint16 length: sizeof(uint16)];
            result = @(uint16);
            break;
        case typeUInt32:
            [desc.data getBytes: &uint32 length: sizeof(uint32)];
            result = @(uint32);
            break;
        case typeSInt64:
            [desc.data getBytes: &sint64 length: sizeof(sint64)];
            result = @(sint64);
            break;
        case typeUInt64:
            [desc.data getBytes: &uint64 length: sizeof(uint64)];
            result = @(uint64);
            break;
        case typeInsertionLoc:
            result = [self unpackInsertionLoc: desc error: error];
            break;
        case typeNull:
            result = [self app]; // note: a null descriptor indicates object specifier root
            break;
        case typeCurrentContainer:
            result = [self con];
            break;
        case typeObjectBeingExamined:
            result = [self its];
            break;
        case typeCompDescriptor:
            result = [self unpackCompDescriptor: desc error: error];
            break;
        case typeLogicalDescriptor:
            result = [self unpackLogicalDescriptor: desc error: error];
            break;
        case typeIEEE32BitFloatingPoint:
            [desc.data getBytes: &float32 length: sizeof(float32)];
            result = @(float32);
            break;
        case type128BitFloatingPoint:
            result = @(desc.doubleValue); // coerces to 64-bit FP
            break;
        case typeQDPoint:
            [desc.data getBytes: &qdPoint length: sizeof(qdPoint)];
            result = @[@(qdPoint[1]), @(qdPoint[0])];
            break;
        case typeQDRectangle:
            [desc.data getBytes: &qdRect length: sizeof(qdRect)];
            result = @[@(qdRect[1]), @(qdRect[0]), @(qdRect[3]), @(qdRect[2])];
            break;
        case typeRGBColor:
            [desc.data getBytes: &rgbColor length: sizeof(rgbColor)];
            result = @[@(rgbColor[0]), @(rgbColor[1]), @(rgbColor[2])];
            break;
        default:
            result = [self unpackUnknown: desc error: error];
    }
    if (!result && error && !*error) { // catch-all in case an unpack method returned nil without an accompanying NSError
        *error = [NSError errorWithDomain: @"NSOSStatusErrorDomain" code: errAECoercionFail userInfo: nil];
    }
    return result;
}

- (id)unpackUnknown:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    MZAppleEventDescriptor *record, *descType;
    if ([desc isRecordDescriptor]) {
        // It's a record-like structure with an unknown/unsupported type, so unpack it
        // as an NSDictionary, including the original type info under a 'class' key.
        record = [desc coerceToDescriptorType: typeAERecord];
        descType = [MZAppleEventDescriptor descriptorWithTypeCode: desc.descriptorType];
        [record setDescriptor: descType forKeyword: pClass];
        return [self unpack: record error: error];
    } else {
        return desc;
    }
}

// methods called by -unpack:; may be overridden by subclasses to modify how values are unpacked

- (id)unpackAEList:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    NSMutableArray *result = [NSMutableArray array];
    NSInteger length = [desc numberOfItems];
    for (NSInteger i=1; i<=length; i++) {
        id item = [self unpack: [desc descriptorAtIndex: i] error: error];
        if (!item) return nil; // TO DO: better error message if not already given
        [result addObject: item];
    }
    return result;
}

- (id)unpackAERecord:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSInteger length = [desc numberOfItems];
    for (NSInteger i = 1; i <= length; i++) {
        AEKeyword key = [desc keywordForDescriptorAtIndex: i];
        MZAppleEventDescriptor *valueDesc = [desc descriptorAtIndex: i];
        if (!valueDesc) return nil; // don't think this will ever happen
        id value = [self unpack: valueDesc error: error];
        if (!value) return nil; // TO DO: better error message if not already given
        if (key == 'usrf') {
            NSInteger length2 = [value count];
            for (NSInteger j = 0; j < length2; j += 2) {
                result[value[j]] = value[j + 1];
            }
        } else {
            id keyObj = [self unpackAERecordKey: key error: error];
            if (!keyObj) return nil; // TO DO: better error message if not already given
            result[keyObj] = value;
        }
    }
    return result;
}

// subclasses can override this method to change how record keys are unpacked:
- (id)unpackAERecordKey:(AEKeyword)key error:(NSError * __autoreleasing *)error {
    return [MZFourCharCode codeWithType: key];
}


- (id)unpackType:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    return [[MZFourCharCode alloc] initWithDescriptor: desc];
}

- (id)unpackEnum:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    return [[MZFourCharCode alloc] initWithDescriptor: desc];
}

- (id)unpackProperty:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    return [[MZFourCharCode alloc] initWithDescriptor: desc];
}

- (id)unpackKeyword:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    return [[MZFourCharCode alloc] initWithDescriptor: desc];
}


- (id)unpackObjectSpecifier:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    /*
    OSType wantCode, keyForm;
    MZAppleEventDescriptor *key;
    id ref, keyObj;
    switch (desc.descriptorType) {
        case typeObjectSpecifier:
            wantCode = [[desc descriptorForKeyword: keyAEDesiredClass] typeCodeValue];
            keyForm = [[desc descriptorForKeyword: keyAEKeyForm] enumCodeValue];
            key = [desc descriptorForKeyword: keyAEKeyData];
            ref = [self unpackObjectSpecifier: [desc descriptorForKeyword: keyAEContainer] error: error];
            if (!ref) return nil;
            switch (keyForm) {
                case formPropertyID:
                    return [ref property: [key typeCodeValue]];
                case formUserPropertyID:
                    keyObj = [self unpack: key error: error];
                    if (!keyObj) return nil;
                    return [ref userProperty: keyObj];
                case formRelativePosition:
                    switch ([key typeCodeValue]) {
                        case kAEPrevious:
                            return [ref previous: wantCode];
                        case kAENext:
                            return [ref next: wantCode];
                        default: // unknown key (should never happen unless object specifier is malformed)
                            return nil;
                    }
            }
            ref = [ref elements: wantCode];
            switch (keyForm) {
                case formAbsolutePosition:
                    if ([key descriptorType] == typeAbsoluteOrdinal) {
                        switch ([key typeCodeValue]) {
                            case kAEAll:
                                return ref;
                            case kAEFirst:
                                return [ref first];
                            case kAEMiddle:
                                return [ref middle];
                            case kAELast:
                                return [ref last];
                            case kAEAny:
                                return [ref any];
                            default: // unknown key (should never happen unless object specifier is malformed)
                                return nil;
                        }
                    } else {
                        keyObj = [self unpack: key error: error];
                        if (!keyObj) return nil;
                        return [ref byIndex: keyObj];
                    }
                case formName:
                    keyObj = [self unpack: key error: error];
                    if (!keyObj) return nil;
                    return [ref byName: keyObj];
                case formUniqueID:
                    keyObj = [self unpack: key error: error];
                    if (!keyObj) return nil;
                    return [ref byID: keyObj];
                case formRange:
                {
                    id startKeyObj = [self unpack: [key descriptorForKeyword: keyAERangeStart] error: error];
                    if (!startKeyObj) return nil;
                    id stopKeyObj = [self unpack: [key descriptorForKeyword: keyAERangeStop] error: error];
                    if (!stopKeyObj) return nil;
                    return [ref byRange: startKeyObj to: stopKeyObj];
                }
                case formTest:
                    keyObj = [self unpack: key error: error];
                    if (!keyObj) return nil;
                    return [ref byTest: keyObj];
            }
        case typeNull:
            return [self app];
        case typeCurrentContainer:
            return [self con];
        case typeObjectBeingExamined:
            return [self its];
        default:
            return [self customRoot: desc error: error];
    }
     */
    return nil;
}


- (id)unpackInsertionLoc:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    /*
    id ref = [self unpack: [desc descriptorForKeyword: keyAEObject] error: error];
    if (!ref) return nil;
    switch ([[desc descriptorForKeyword: keyAEPosition] enumCodeValue]) {
        case kAEBeginning:
            return [ref beginning];
        case kAEEnd:
            return [ref end];
        case kAEBefore:
            return [ref before];
        case kAEAfter:
            return [ref after];
        default: // unknown key (should never happen unless object specifier is malformed)
            return nil;
    }
    */
    return nil;
}


- (id)app {
    return nil; //AEMApp;
}

- (id)con {
    return nil; //AEMCon;
}

- (id)its {
    return nil; //AEMIts;
}

- (id)customRoot:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error {
    /*
    id rootValue = [self unpack: desc error: error];
    return rootValue ? AEMRoot(rootValue) : nil;
     */
    return nil;
}

- (id)unpackCompDescriptor:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error { // TO DO: better error reporting
    /*
    DescType operator = [[desc descriptorForKeyword: keyAECompOperator] enumCodeValue];
    id op1 = [self unpack: [desc descriptorForKeyword: keyAEObject1] error: error];
    if (!op1) return nil;
    id op2 = [self unpack: [desc descriptorForKeyword: keyAEObject2] error: error];
    if (!op2) return nil;
    switch (operator) {
        case kAEGreaterThan:
            return [op1 greaterThan: op2];
        case kAEGreaterThanEquals:
            return [op1 greaterOrEquals: op2];
        case kAEEquals:
            return [op1 equals: op2];
        case kAELessThan:
            return [op1 lessThan: op2];
        case kAELessThanEquals:
            return [op1 lessOrEquals: op2];
        case kAEBeginsWith:
            return [op1 beginsWith: op2];
        case kAEEndsWith:
            return [op1 endsWith: op2];
        case kAEContains:
            return [self unpackContainsCompDescriptorWithOperand1: op1 operand2: op2 error: error];
    }
    */
    return nil;
}

- (id)unpackLogicalDescriptor:(MZAppleEventDescriptor *)desc error:(NSError * __autoreleasing *)error { // TO DO: better error reporting
    /*
    MZAppleEventDescriptor *listDesc;
    listDesc = [[desc descriptorForKeyword: keyAELogicalTerms] coerceToDescriptorType: typeAEList]; // TO DO: should unpack as list of comparison/logic descs, raising error if any are not
    DescType operator = [[desc descriptorForKeyword: keyAELogicalOperator] enumCodeValue];
    id ops, op1 = [self unpack: [listDesc descriptorAtIndex: 1] error: error];
    if (!op1) return nil;
    switch (operator) {
        case kAEAND:
            [listDesc removeDescriptorAtIndex: 1];
            ops = [self unpack: listDesc error: error];
            return ops ? [op1 AND: ops] : nil; // TO DO: better to chain single operands rather than use array of operands?
        case kAEOR:
            [listDesc removeDescriptorAtIndex: 1];
            ops = [self unpack: listDesc error: error];
            return ops ? [op1 OR: ops] : nil;
        case kAENOT:
            return [op1 NOT];
    }
    */
    return nil;
}

- (id)unpackContainsCompDescriptorWithOperand1:(id)op1 operand2:(id)op2 error:(NSError * __autoreleasing *)error {
    /*
    if ([op1 isKindOfClass: AEMTestClause.class]) { // check op1 is an its-based test specifier, e.g. `its text contains "foo"`
        return [op1 contains: op2];
    } else { // else op2 is [presumably] the its-based specifier, e.g. `its name is in {"bar", "baz", "fub"}`
        return [op2 isIn: op1];
    }
     */
    return nil;
}

@end

