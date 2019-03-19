//
//  MZFourCharCode.m
//

#import "MZFourCharCode.h"

@implementation MZFourCharCode


+ (instancetype)codeWithType:(OSType)typeCode {
    return [[self alloc] initWithDescriptorType: typeType codeValue: typeCode];
}

+ (instancetype)codeWithEnum:(OSType)enumCode {
    return [[self alloc] initWithDescriptorType: typeEnumerated codeValue: enumCode];
}

- (instancetype)initWithDescriptorType:(DescType)descType codeValue:(OSType)codeValue {
    self = [super init];
    if (self) {
        type = descType;
        code = codeValue;
        descriptor = [[MZAppleEventDescriptor alloc] initWithDescriptorType: descType
                                                                      bytes: &codeValue
                                                                     length: sizeof(codeValue)];
    }
    return self;
}

- (instancetype)initWithDescriptor:(MZAppleEventDescriptor *)desc {
    self = [super init];
    if (self) {
        type = desc.descriptorType;
        [desc.data getBytes: &code length: sizeof(code)];
        descriptor = desc;
    }
    return self;
}

- (DescType) type {
    return type;
}
- (OSType)code {
    return code;
}
- (MZAppleEventDescriptor *)descriptor {
    return descriptor;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (NSUInteger)hash {
    return (NSUInteger)code;
}
- (BOOL)isEqual:(id)anObject {
    if (anObject == self) return YES;
    if (!anObject || ![anObject isKindOfClass: self.class]) return NO;
    return code == ((MZFourCharCode *)anObject).code;
}

- (NSString *)description {
    switch (type) {
        case typeType:
            return [NSString stringWithFormat: @"[MZFourCharCode typeWithCode: %@]", MZFormatFourCharCode(code)];
        case typeEnumerated:
            return [NSString stringWithFormat: @"[MZFourCharCode enumWithCode: %@]", MZFormatFourCharCode(code)];
        default:
            return [NSString stringWithFormat: @"[[MZFourCharCode alloc] initWithType: %@ code: %@]",
                    MZFormatFourCharCode(type), MZFormatFourCharCode(code)];
    }
}

@end


NSString *MZFormatFourCharCode(OSType code) {
    code = CFSwapInt32HostToBig(code);
    NSMutableString *str = [NSMutableString stringWithCapacity: 6];
    [str appendString: @"'"];
    for (int i = 0; i < sizeof(code); i++) {
        char c = ((char*)(&code))[i];
        if (c < 32 || c > 126 || c == '\\' || c == '\'') {
            return [NSString stringWithFormat: @"0x%08x", code];
        }
        [str appendFormat: @"%c", c];
    }
    [str appendString: @"'"];
    return str;
}

