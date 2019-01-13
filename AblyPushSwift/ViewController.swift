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

    var realtime: ARTRealtime!

    override func viewDidLoad() {
        super.viewDidLoad()
        let options = ARTClientOptions(key: "EyOMzQ._NdWJA:rb6YHb1h7YZuu45X")
        options.clientId = UIDevice.current.identifierForVendor!.uuidString
        print("ClientId", options.clientId ?? "nil")
        realtime = ARTRealtime(options: options)
    }

    @IBAction func buttonTapped(_ sender: Any) {
        let message = ARTMessage(name: "simulator", data: "")
        message.extras = [
            "push": [
                "notification": [
                    "title": "Hello from Ably!",
                    "body": "Example push notification from Ably."
                ],
                "data": [
                    "foo": "bar",
                    "baz": "qux"
                ]
            ]
        ] as NSDictionary
        
        realtime.channels.get("groups").publish([message]) { error in
            print("Publish notification", error ?? "nil")
        }
    }
    
}
