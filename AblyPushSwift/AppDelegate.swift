//
//  AppDelegate.swift
//  AblyPushSwift
//
//  Created by Ricardo Pereira on 03/10/2018.
//  Copyright © 2018 Whitesmith. All rights reserved.
//

import UIKit
import Ably
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ARTPushRegistererDelegate {

    var window: UIWindow?
    var realtime: ARTRealtime!

    #if DEBUG
    static let AblyKey = "<debug_key>"
    #else
    static let AblyKey = "<release_key>"
    #endif
    static let AblySandbox = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let options = ARTClientOptions(key: AppDelegate.AblyKey)
        options.clientId = UIDevice.current.identifierForVendor!.uuidString
        if AppDelegate.AblySandbox {
            options.environment = "sandbox"
        }

        realtime = ARTRealtime(options: options)

        UNUserNotificationCenter.current().delegate = self

        requestPushNotificationPermissions()

        realtime.push.activate()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: realtime)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: realtime)
    }

    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        print("Ably Push Activation:", error ?? "no error")

        if error == nil {
            // You can only use device after device activation has finished
            //realtime.channels.get("groups").push.subscribeDevice() { error in
            //    print("SubscribeDevice", error ?? "nil")
            //}

            // You can only use device after device activation has finished
            //realtime.channels.get("groups").push.subscribeClient() { error in
            //    print("Activated SubscribeClient", error ?? "nil")
            //}
        }
    }

    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("Ably Push Deactivation:", error ?? "no error")
    }

    func _ablyPushCustomRegister(_ error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void) {
        if let e = error {
            // Handle error.
            callback(nil, e)
            return
        }

        self.registerThroughYourServer(deviceDetails: deviceDetails, callback: callback)
    }

    func _ablyPushCustomDeregister(_ error: ARTErrorInfo?, deviceId: String, callback: ((ARTErrorInfo?) -> Void)? = nil) {
        print(deviceId)
    }

    private func registerThroughYourServer(deviceDetails: ARTDeviceDetails, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            callback(nil, nil)
        }
    }

}

extension AppDelegate {

    fileprivate func requestPushNotificationPermissions() {
        AppDelegate.requestPushNotificationPermissions()
    }

    class func requestPushNotificationPermissions() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        UNUserNotificationCenter.current().requestAuthorization(
            options: options,
            completionHandler: { granted, error in
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        )
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Tell the app that we have finished processing the user’s action (eg: tap on notification banner) / response
        // Handle received remoteNotification: 'response.notification.request.content.userInfo'
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification alert (banner)
        completionHandler([.alert, .sound])
    }

}
