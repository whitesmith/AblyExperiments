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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let options = ARTClientOptions(key: "EyOMzQ._NdWJA:rb6YHb1h7YZuu45X")
        options.clientId = UIDevice.current.identifierForVendor!.uuidString

        realtime = ARTRealtime(options: options)

        UNUserNotificationCenter.current().delegate = self

        requestPushNotificationPermissions()

        realtime.push.activate()

        // You can only use device after device activation has finished
        realtime.channels.get("groups").push.subscribeClient() { error in
            print("subscribeClient", error ?? "nil")
        }

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
//            // You can only use device after device activation has finished
//            realtime.channels.get("groups").push.subscribeDevice() { error in
//                print("SubscribeDevice", error ?? "nil")
//            }
        }
    }

    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("Ably Push Deactivation:", error ?? "no error")
    }

    private func requestPushNotificationPermissions() {
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
