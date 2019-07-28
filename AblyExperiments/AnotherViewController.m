//
//  AnotherViewController.m
//  AblyPushSwift
//
//  Created by Ricardo Pereira on 21/12/2018.
//  Copyright © 2018 Whitesmith. All rights reserved.
//

#import "AnotherViewController.h"
#import <Ably/Ably.h>

@implementation AnotherViewController

- (void)didActivateAblyPush:(ARTErrorInfo *)error {
}

- (void)didDeactivateAblyPush:(ARTErrorInfo *)error {
}

- (void)ablyPushCustomRegister:(ARTErrorInfo *)error deviceDetails:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceIdentityTokenDetails * _Nullable, ARTErrorInfo * _Nullable))callback {
    if (error) {
        // Handle error.
        callback(nil, error);
        return;
    }

    [self registerThroughYourServer:deviceDetails callback:callback];
}

- (void)ablyPushCustomDeregister:(ARTErrorInfo *)error deviceId:(ARTDeviceId *)deviceId callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    // TODO
}

- (void)registerThroughYourServer:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceIdentityTokenDetails * _Nullable, ARTErrorInfo * _Nullable))callback {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_BACKGROUND), ^{
        NSError *error;
        callback(nil, [ARTErrorInfo createFromNSError:error]);
    });
}

@end
