//
//  ViewController.swift
//  AblyPushSwift
//
//  Created by Ricardo Pereira on 03/10/2018.
//  Copyright © 2018 Whitesmith. All rights reserved.
//

import UIKit
import Ably

class ViewController: UIViewController {

    let options = ARTClientOptions(key: AppDelegate.AblyKey)

    var realtime: ARTRealtime!
    var fooChannel: ARTRealtimeChannel!
    var rest: ARTRest!

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        options.logLevel = .verbose
        
        if AppDelegate.Options.useSandbox {
            options.environment = "sandbox"
        }
        if !AppDelegate.Options.initializeClientIdAfterLaunching {
            options.clientId = UIDevice.current.identifierForVendor!.uuidString
        }

        rest = ARTRest(options: options)

        realtime = ARTRealtime(options: options)
        fooChannel = realtime.channels.get("foo")
        fooChannel.attach()

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAblyPushDidActivate), name: .ablyPushDidActivate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAblyPushDidDeactivate), name: .ablyPushDidDeactivate, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAblyPushDidReceivedNotification), name: .ablyPushDidReceivedNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logInfo("AppID: " + String(options.key?.prefix(6) ?? "no key"))
        logInfo("Env: " + (options.environment.isEmpty ? "production" : options.environment))
        #if DEBUG
        logInfo("Mode: DEBUG")
        #else
        logInfo("Mode: RELEASE")
        #endif
        logInfo("ClientID: " + (options.clientId ?? "nil"))
        logInfo("DeviceID: " + rest.device.id)
        logInfo("DeviceToken: " + (UserDefaults.standard.string(forKey: "ARTDeviceToken") ?? "nil"))
    }

    @objc func handleAblyPushDidActivate(notification: Notification) {
        if let error = notification.userInfo?["Error"] as? ARTErrorInfo {
            logInfo(#function+":", error.debugDescription)
            return
        }
        logInfo(#function+":", "no error")
    }

    @objc func handleAblyPushDidDeactivate(notification: Notification) {
        if let error = notification.userInfo?["Error"] as? ARTErrorInfo {
            logInfo(#function+":", error.debugDescription)
            return
        }
        logInfo(#function+":", "no error")
    }

    @objc func handleAblyPushDidReceivedNotification(notification: Notification) {
        logInfo(#function+":", notification.userInfo?.debugDescription ?? "no info")
    }

    @IBAction func sendNotificationButtonTapped(_ sender: Any) {
        let push: [String: Any] = [
            "notification": [
                "title": "Hello from Ably!",
                "body": "Example push notification from Ably."
            ],
            "data": [
                "foo": "bar",
                "baz": "qux"
            ]
        ]

        let message = ARTMessage(name: "experiment", data: "")
        message.extras = [
            "push": push
        ] as NSDictionary

        rest.channels.get("groups").publish([message]) { error in
            self.logInfo("Notification published:", error?.debugDescription ?? "nil")
        }
    }

    @IBAction func sendNotificationWithAdminTapped(_ sender: Any) {
        let push: [String: Any] = [
            "apns": [
                "aps": [
                    "content-available": 1
                ],
                "apns-headers": [
                    "apns-push-type": "background",
                    "apns-priority": 5
                ]
            ],
            "data": [
                "proto-data": "Hello from Ably!"
            ]
        ]

        let message = ARTMessage(name: "experiment", data: "")
        message.extras = [
            "push": push
        ] as NSDictionary

        let recipient: [String: Any] = [
            "deviceId": "0001EHSJBS00GW0X476W5TVBFE"
            //"clientId": "C03BC116-8004-4D78-A71F-8CA3122734DB"
        ]

        rest.push.admin.publish(recipient, data: push) { error in
            self.logInfo("Notification published:", error?.debugDescription ?? "nil")
        }
    }
    
    @IBAction func subscribeClientButtonTapped(_ sender: Any) {
        rest.channels.get("groups").push.subscribeClient() { error in
            let e: String = error?.debugDescription ?? "nil"
            print("Subscribe Client:", error ?? "nil")
            self.textView.text += "\n" + "Subscribe Client: \(e)"
        }
    }

    @IBAction func subscribeDeviceButtonTapped(_ sender: Any) {
        rest.channels.get("groups").push.subscribeDevice() { error in
            let e: String = error?.debugDescription ?? "nil"
            print("Subscribe Device:", error ?? "nil")
            self.textView.text += "\n" + "Subscribe Device: \(e)"
        }
    }

    @IBAction func activateButtonTapped(_ sender: Any) {
        logInfo("Push Activate called")
        rest.push.activate()
    }

    @IBAction func deactivateButtonTapped(_ sender: Any) {
        logInfo("Push Deactivate called")
        rest.push.deactivate()
    }

    @IBAction func requestPermissionsButtonTapped(_ sender: Any) {
        logInfo("Request permissions")
        AppDelegate.requestPushNotificationPermissions()
    }

    @IBAction func registerRemoteNotificationsButtonTapped(_ sender: Any) {
        logInfo("Register for Remote notifications")
        UIApplication.shared.registerForRemoteNotifications()
    }

    @IBAction func unregisterRemoteNotificationsButtonTapped(_ sender: Any) {
        logInfo("Unregister for Remote notifications")
        UIApplication.shared.unregisterForRemoteNotifications()
    }

    private func logInfo(_ info: String...) {
        let message = info.joined(separator: " ")
        print(message)
        self.textView.text += "\n" + message
    }

}
