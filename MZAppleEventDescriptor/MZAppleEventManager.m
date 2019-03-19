//
//  MZAppleEventManager.m
//

#import "MZAppleEventManager.h"


static OSErr MZGenericEventHandler(const AppleEvent *request, AppleEvent *reply, SRefCon refcon) {
    NSInvocation *call = ((__bridge NSInvocation *)refcon);
    MZAppleEventDescriptor *requestDesc = [[MZAppleEventDescriptor alloc] initWithAEDescNoCopy: request];
    requestDesc->_owned = NO;
    MZAppleEventDescriptor *replyDesc = [[MZAppleEventDescriptor alloc] initWithAEDescNoCopy: reply];
    replyDesc->_owned = NO;
    [call setArgument: (__bridge void * _Nonnull)(requestDesc) atIndex: 0];
    [call setArgument: (__bridge void * _Nonnull)(replyDesc) atIndex: 1];
    [call invoke];
    return 0;
}


@implementation MZAppleEventManager

// BOOL _isPreparedForDispatch;
// char _padding[3];

// Get the pointer to the program's single MZAppleEventManager.
+ (MZAppleEventManager *)sharedAppleEventManager {
    static dispatch_once_t pred = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        handleEventSignature = [NSMethodSignature signatureWithObjCTypes: "i@:@@"];
        genericEventHandlerUPP = NewAEEventHandlerUPP(MZGenericEventHandler);
    }
    return self;
}

// Set or remove a handler for a specific kind of Apple Event.  The handler method should have the same signature as:
// - (void)handleAppleEvent:(MZAppleEventDescriptor *)event withReplyEvent:(MZAppleEventDescriptor *)replyEvent;
// When it is invoked, the value of the first parameter will be the event to be handled.  The value of the second parameter will be the reply event to fill in.  A reply event object will always be passed in (replyEvent will never be nil), but it should not be touched if the event sender has not requested a reply, which is indicated by [replyEvent descriptorType]==typeNull.
- (void)setEventHandler:(id)handler andSelector:(SEL)handleEventSelector
          forEventClass:(AEEventClass)eventClass andEventID:(AEEventID)eventID {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: handleEventSignature];
    invocation.target = handler;
    invocation.selector = handleEventSelector;
    OSErr err = AEInstallEventHandler(eventClass,
                                      eventID,
                                      genericEventHandlerUPP, (__bridge SRefCon)invocation,
                                      false);
    if (err) NSLog(@"Failed to install AE handler %08x/%08x: %i", eventClass, eventID, err);
}

- (void)removeEventHandlerForEventClass:(AEEventClass)eventClass andEventID:(AEEventID)eventID {
    AERemoveEventHandler(eventClass, eventID, NULL, false); // leaks an NSInvocation instance
}

// Given an event, reply event, and refCon of the sort passed into Apple event handler functions that can be registered with AEInstallEventHandler(), dispatch the event to a handler that has been registered with -setEventHandler:andSelector:forEventClass:andEventID:.
// This method is primarily meant for Cocoa's internal use.  It does not send events to other applications!
- (OSErr)dispatchRawAppleEvent:(const AppleEvent *)theAppleEvent
                  withRawReply:(AppleEvent *)theReply handlerRefCon:(SRefCon)handlerRefCon {
    return 1;
}

// If an Apple event is being handled on the current thread (i.e., a handler that was registered with -setEventHandler:andSelector:forEventClass:andEventID: is being messaged at this instant or -setCurrentAppleEventAndReplyEventWithSuspensionID: has just been invoked), return the descriptor for the event.  Return nil otherwise.  The effects of mutating or retaining the returned descriptor are undefined, though it may be copied.
- (MZAppleEventDescriptor *)currentAppleEvent { // @property (nullable, readonly, retain)
    return nil;
}

// If an Apple event is being handled on the current thread (i.e., -currentAppleEvent would not return nil), return the corresponding reply event descriptor.  Return nil otherwise.  This descriptor, including any mutatations, will be returned to the sender of the current event when all handling of the event has been completed, if the sender has requested a reply.  The effects of retaining the descriptor are undefined; it may be copied, but mutations of the copy will not be returned to the sender of the current event.
- (MZAppleEventDescriptor *)currentReplyAppleEvent { // @property (nullable, readonly, retain)
    return nil;
}

// If an Apple event is being handled on the current thread (i.e., -currentAppleEvent would not return nil), suspend the handling of the event, returning an ID that must be used to resume the handling of the event.  Return zero otherwise.  The suspended event will no longer be the current event after this method has returned.
- (nullable MZAppleEventManagerSuspensionID)suspendCurrentAppleEvent { // NS_RETURNS_INNER_POINTER
    return nil;
}

// Given a nonzero suspension ID returned by an invocation of -suspendCurrentAppleEvent, return the descriptor for the event whose handling was suspended.  The effects of mutating or retaining the returned descriptor are undefined, though it may be copied.  This method may be invoked in any thread, not just the one in which the corresponding invocation of -suspendCurrentAppleEvent occurred.
- (MZAppleEventDescriptor *)appleEventForSuspensionID:(MZAppleEventManagerSuspensionID)suspensionID {
    return nil;
}

// Given a nonzero suspension ID returned by an invocation of -suspendCurrentAppleEvent, return the corresponding reply event descriptor.  This descriptor, including any mutatations, will be returned to the sender of the suspended event when handling of the event is resumed, if the sender has requested a reply.  The effects of retaining the descriptor are undefined; it may be copied, but mutations of the copy will not be returned to the sender of the suspended event.  This method may be invoked in any thread, not just the one in which the corresponding invocation of -suspendCurrentAppleEvent occurred.
- (MZAppleEventDescriptor *)replyAppleEventForSuspensionID:(MZAppleEventManagerSuspensionID)suspensionID {
    return nil;
}

// Given a nonzero suspension ID returned by an invocation of -suspendCurrentAppleEvent, set the values that will be returned by subsequent invocations of -currentAppleEvent and -currentReplyAppleEvent to be the event whose handling was suspended and its corresponding reply event, respectively.  Redundant invocations of this method will be ignored.
- (void)setCurrentAppleEventAndReplyEventWithSuspensionID:(MZAppleEventManagerSuspensionID)suspensionID {
}

// Given a nonzero suspension ID returned by an invocation of -suspendCurrentAppleEvent, signal that handling of the suspended event may now continue.  This may result in the immediate sending of the reply event to the sender of the suspended event, if the sender has requested a reply.  If the suspension ID has been used in a previous invocation of -setCurrentAppleEventAndReplyEventWithSuspensionID: the effects of that invocation will be completely undone.  Subsequent invocations of other MZAppleEventManager methods using the same suspension ID are invalid.  This method may be invoked in any thread, not just the one in which the corresponding invocation of -suspendCurrentAppleEvent occurred.
- (void)resumeWithSuspensionID:(MZAppleEventManagerSuspensionID)suspensionID {
}

@end
