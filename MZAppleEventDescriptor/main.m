//
//  main.m
//  MZAppleEventDescriptor
//

#import <Foundation/Foundation.h>
#import "MZAppleEventDescriptor.h"
#import "MZAppleEventConverter.h"
#import "MZFourCharCode.h"



int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // NSLog(@"|%@|", [MZAppleEventDescriptor descriptorWithString: @"hello"].stringValue);
        // NSLog(@"|%i|", [MZAppleEventDescriptor descriptorWithInt32: 42].int32Value);
        // NSLog(@"|%@|", [MZAppleEventDescriptor descriptorWithInt32: 42].stringValue);

        // NSLog(@"|%@|", [MZAppleEventDescriptor descriptorWithDate: [NSDate dateWithTimeIntervalSince1970: 3600]].dateValue);

        // NSLog(@"|%@|", [MZAppleEventDescriptor descriptorWithInt32: 42]);
        // NSLog(@"|%f|", [MZAppleEventDescriptor descriptorWithInt32: 42].doubleValue);
        // NSLog(@"|%f|", [MZAppleEventDescriptor descriptorWithDouble: 3.14].doubleValue);
        // NSLog(@"|%i|", [MZAppleEventDescriptor descriptorWithDouble: 3.14].int32Value);
        // NSLog(@"|%f|", [MZAppleEventDescriptor descriptorWithString: @"hello"].doubleValue);
        // NSLog(@"|%@|", [[[MZAppleEventDescriptor descriptorWithInt32: 3] coerceToDescriptorType: typeIEEE64BitFloatingPoint] coerceToDescriptorType: typeUnicodeText]);
        
        // NSLog(@"|%i|", [MZAppleEventDescriptor descriptorWithBoolean: true].booleanValue);
        // NSLog(@"|%i|", [MZAppleEventDescriptor descriptorWithBoolean: false].booleanValue);
        
        //NSLog(@"|%@|", [[MZAppleEventDescriptor descriptorWithInt32: 1] coerceToDescriptorType: typeBoolean]);
        //NSLog(@"|%i|", [[MZAppleEventDescriptor descriptorWithInt32: 1] coerceToDescriptorType: typeBoolean].booleanValue);
        //NSLog(@"|%i|", [MZAppleEventDescriptor descriptorWithInt32: 1].booleanValue);
        //NSLog(@"|%i|", [NSAppleEventDescriptor descriptorWithInt32: 1].booleanValue);
        
        /*
        MZAppleEventDescriptor *listDesc = [MZAppleEventDescriptor listDescriptor];
        if (!listDesc) { return 1; }
        [listDesc insertDescriptor: [MZAppleEventDescriptor descriptorWithString: @"ONE"] atIndex: 0];
        [listDesc insertDescriptor: [MZAppleEventDescriptor descriptorWithString: @"TWO"] atIndex: 0];
        NSLog(@"%@", listDesc);
        NSLog(@"%@", [listDesc descriptorAtIndex: 1]);
        NSLog(@"%@", [listDesc descriptorAtIndex: 2]);
        NSLog(@"%@", [listDesc descriptorAtIndex: 99]);
        NSLog(@"%i", listDesc.isRecordDescriptor);
        
        
        MZAppleEventDescriptor *recoDesc = [MZAppleEventDescriptor recordDescriptor];
        if (!recoDesc) { return 1; }
        [recoDesc setDescriptor: [MZAppleEventDescriptor descriptorWithString: @"ONE"] forKeyword: 'aaaa'];
       // [recoDesc insertDescriptor: [MZAppleEventDescriptor descriptorWithString: @"TWO"] atIndex: 0];
        NSLog(@"%@", recoDesc);
        NSLog(@"%@", [recoDesc descriptorAtIndex: 1]);
        NSLog(@"%08x", [recoDesc keywordForDescriptorAtIndex: 1]); // 61616161
        NSLog(@"%@", [recoDesc descriptorForKeyword: 'aaaa']);
        NSLog(@"%@", [recoDesc descriptorForKeyword: 'bbbb']);
        NSLog(@"%i", recoDesc.isRecordDescriptor);
        */
        
        MZAppleEventDescriptor *target = [MZAppleEventDescriptor descriptorWithBundleIdentifier: @"com.apple.finder"];
        MZAppleEventDescriptor *event = [MZAppleEventDescriptor appleEventWithEventClass: 'core' eventID: 'getd'
                                                                        targetDescriptor: target
                                                                                returnID: kAutoGenerateReturnID
                                                                           transactionID: kAnyTransactionID];
        
        MZAppleEventDescriptor *objSpec = [[MZAppleEventDescriptor recordDescriptor] coerceToDescriptorType: typeObjectSpecifier];
        if (!objSpec) { return 1; }
        [objSpec setDescriptor: [MZAppleEventDescriptor descriptorWithTypeCode: cProperty] forKeyword: 'want'];
        [objSpec setDescriptor: [MZAppleEventDescriptor nullDescriptor] forKeyword: 'from'];
        [objSpec setDescriptor: [MZAppleEventDescriptor descriptorWithEnumCode: formPropertyID] forKeyword: 'form'];
        [objSpec setDescriptor: [MZAppleEventDescriptor descriptorWithTypeCode: 'home'] forKeyword: 'seld'];
        [event setDescriptor: objSpec forKeyword: '----'];
        
        NSLog(@"%@", event);
        NSError *error = nil;
        MZAppleEventDescriptor *reply = [event sendEventWithOptions: kAEWaitReply timeout: 60 error: &error];
        if (reply) {
            NSLog(@"REP: %@", reply);
        } else {
            NSLog(@"ERR: %@", error);
        }
        
//        NSAppleEventManager
        
    }
    return 0;
}
