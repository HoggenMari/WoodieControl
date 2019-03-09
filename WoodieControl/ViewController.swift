//
//  ViewController.swift
//  WoodieControl
//
//  Created by Marius Hoggenmueller on 9/3/19.
//  Copyright © 2019 Marius Hoggenmueller. All rights reserved.
//

import UIKit
import SwiftSocket
import CocoaMQTT

class ViewController: UIViewController {

    let mqttClient = CocoaMQTT(clientID: "iOS Device", host: "192.168.0.102", port: 6667)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let client = TCPClient(address: "192.168.0.102", port: 9000)
        switch client.connect(timeout: 1) {
        case .success:
            switch client.send(string: "Blaaaaaa" ) {
            case .success:
                guard let data = client.read(1024*10) else { return }
                
                if let response = String(bytes: data, encoding: .utf8) {
                    print(response)
                }
            case .failure(let error):
                print(error)
            }
        case .failure(let error):
            print(error)
        }
    }

    @IBAction func connect(_ sender: Any) {
        mqttClient.connect()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        mqttClient.disconnect()
    }
    
    @IBAction func reboot(_ sender: Any) {
        mqttClient.publish("rpi/reboot", withString: "true")
    }
}

