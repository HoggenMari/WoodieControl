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

class ViewController: UIViewController, CocoaMQTTDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var mqttClient: CocoaMQTT!
    
    @IBOutlet weak var gcodeTextField: UITextField!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var gocdeTxt: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var shutdownBtn: UIButton!
    @IBOutlet weak var rebootBtn: UIButton!
    @IBOutlet weak var ipAddressField: UITextField!
    @IBOutlet weak var cameraContainerView: UIView!
    
    let DEFAULT_IP = "192.168.0.102"
    
    var isConnected:Bool {
        get {
            return self.isConnected
        }
        set(isConnected) {
            setUI(for: isConnected)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mqttClient = CocoaMQTT(clientID: "iOS Device", host: ipAddressField.text ?? DEFAULT_IP, port: 6667)
        isConnected = false
        
        self.hideKeyboardWhenTappedAround()
        mqttClient.delegate = self
        
        cameraContainerView.addSubview((appDelegate.videoViewController?.view)!)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mqttClient.ping()
        isConnected = false
    }

    @IBAction func connect(_ sender: Any) {
        //mqttClient = CocoaMQTT(clientID: "iOS Device", host: ipAddressField.text ?? "192.168.0.102", port: 6667)
        mqttClient.host = ipAddressField.text ?? DEFAULT_IP
        mqttClient.connect()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        mqttClient.disconnect()
    }
    
    @IBAction func reboot(_ sender: Any) {
        mqttClient.publish("rpi", withString: "reboot")
    }
    
    @IBAction func shutdown(_ sender: Any) {
        mqttClient.publish("rpi", withString: "shutdown")
    }
    
    
    @IBAction func sendGcode(_ sender: Any) {
        if let text = gcodeTextField.text {
            mqttClient.publish("gcode", withString: text)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        isConnected = true
        print("didConnectAck")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didReceiveMessage")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("mqttDidPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        isConnected = true
        print("mqttDidReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        isConnected = false
        print("mqttDidDisconnect")
    }
    
    func setUI(for connected: Bool) {
        if connected {
            disconnectBtn.isEnabled = true
            disconnectBtn.alpha = 1.0
            gocdeTxt.isEnabled = true
            gocdeTxt.alpha = 1.0
            sendBtn.isEnabled = true
            sendBtn.alpha = 1.0
            shutdownBtn.isEnabled = true
            shutdownBtn.alpha = 1.0
            rebootBtn.isEnabled = true
            rebootBtn.alpha = 1.0
        } else {
            disconnectBtn.isEnabled = false
            disconnectBtn.alpha = 0.5
            gocdeTxt.isEnabled = false
            gocdeTxt.alpha = 0.5
            sendBtn.isEnabled = false
            sendBtn.alpha = 0.5
            shutdownBtn.isEnabled = false
            shutdownBtn.alpha = 0.5
            rebootBtn.isEnabled = false
            rebootBtn.alpha = 0.5
        }
    }
    
}

