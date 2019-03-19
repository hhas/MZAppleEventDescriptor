//
//  MZFourCharCode.h
//

#import <Foundation/Foundation.h>
#import "MZAppleEventDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MZFourCharCode : NSObject <NSCopying> {
    DescType type;
    OSType code;
    MZAppleEventDescriptor *descriptor;
}

+ (instancetype)codeWithType:(OSType)typeCode;
+ (instancetype)codeWithEnum:(OSType)enumCode;

- (instancetype)initWithDescriptorType:(DescType)descType codeValue:(OSType)codeValue;

- (instancetype)initWithDescriptor:(MZAppleEventDescriptor *)desc; // normally called by -unpack:, though clients could also use it to wrap any loose MZAppleEventDescriptor instances they might have. Caution: descriptor isn't validated; clients are responsible for providing appropriate values

- (DescType) type;
- (OSType)code;
- (MZAppleEventDescriptor *)descriptor;

@end

// formats an OSType as C literal, e.g. 'abcd', 0x11223344
NSString *MZFormatFourCharCode(OSType codeValue);


NS_ASSUME_NONNULL_END
