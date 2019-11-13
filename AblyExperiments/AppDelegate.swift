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

extension Notification.Name {
    static let ablyPushDidActivate = Notification.Name(rawValue: "ablyPushDidActivate")
    static let ablyPushDidDeactivate = Notification.Name(rawValue: "ablyPushDidDeactivate")
    static let ablyPushDidReceivedNotification = Notification.Name(rawValue: "ablyPushDidReceivedNotification")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ARTPushRegistererDelegate {

    final class Options {
        static let useSandbox = false
        static let initializeClientIdAfterLaunching = false
        static let requestPermissionsAfterLaunching = false
    }

    var window: UIWindow?
    var realtime: ARTRealtime!

    #if DEBUG
        #if targetEnvironment(simulator)
        static let AblyKey = "<debug_key>"
        #else
        static let AblyKey = "<debug_key_sub_only>" //subscribe only
        #endif
    #else
    static let AblyKey = "<release_key>"
    #endif

    private var lastDate: Date = Date()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let options = ARTClientOptions(key: AppDelegate.AblyKey)
        options.logLevel = .verbose

        if !Options.initializeClientIdAfterLaunching {
            options.clientId = UIDevice.current.identifierForVendor!.uuidString
        }
        else {
            options.authCallback = { _, completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    let tokenDetails = ARTTokenDetails(
                        token: "",
                        expires: Date().addingTimeInterval(3600),
                        issued: Date(),
                        capability: "{\"[*]*\":[\"channel-metadata\",\"history\",\"presence\",\"publish\",\"push-subscribe\",\"subscribe\"]}",
                        clientId: ""
                    )
                    completion(tokenDetails, nil)
                })
            }
        }

        if Options.useSandbox {
            options.environment = "sandbox"
        }

        realtime = ARTRealtime(options: options)

        realtime.connection.on { [weak self] stateChange in
            guard let stateChange = stateChange else {
                print("'stateChange' is nil")
                return
            }
            let statusChange = ARTRealtimeConnectionStateToStr(stateChange.previous) + " -> " + ARTRealtimeConnectionStateToStr(stateChange.current)

            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.calendar = Calendar.current
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            print(dateFormatter.string(from: currentDate), currentDate.timeIntervalSince(self!.lastDate), statusChange)
            self?.lastDate = currentDate

            if stateChange.current == .connected, let tokenDetails = self?.realtime.auth.tokenDetails {
                print("Current TokenDetails", tokenDetails)
            }
        }

        UNUserNotificationCenter.current().delegate = self

        if Options.requestPermissionsAfterLaunching {
            requestPushNotificationPermissions()
        }

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
        NotificationCenter.default.post(name: .ablyPushDidActivate, object: nil, userInfo: ["Error": error as Any])
    }

    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("Ably Push Deactivation:", error ?? "no error")
        NotificationCenter.default.post(name: .ablyPushDidDeactivate, object: nil, userInfo: ["Error": error as Any])
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

    // MARK: - Remote Notifications

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        guard let userInfo = userInfo as? [String: AnyObject] else {
            return
        }
        print("Remote Notification:", userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if (userInfo["aps"] as? [String: Any])?["alert"] != nil {
            print("Remote Notification with completion handler:", userInfo)
            completionHandler(.noData)
            return
        }
        print("Background Notification:", userInfo)
        completionHandler(.noData)
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
                // This is not mandatory
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
        print("UNUserNotificationCenterDelegate: did receive notification")
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification alert (banner)
        completionHandler([.alert, .sound])
        print("UNUserNotificationCenterDelegate: will present notification")
        NotificationCenter.default.post(name: .ablyPushDidReceivedNotification, object: nil, userInfo: notification.request.content.userInfo)
    }

}
