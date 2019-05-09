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
import SystemConfiguration.CaptiveNetwork

class ViewController: UIViewController, CocoaMQTTDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
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
    @IBOutlet weak var wifiField: UITextField!
    @IBOutlet weak var cameraContainerView: UIView!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var turboUpButton: UIButton!
    @IBOutlet weak var turboDownButton: UIButton!
    @IBOutlet weak var moveUpButton: UIButton!
    @IBOutlet weak var moveDownButton: UIButton!
    @IBOutlet weak var moveLeftButton: UIButton!
    @IBOutlet weak var moveRightButton: UIButton!
    @IBOutlet weak var moveStepper: UIStepper!
    @IBOutlet weak var moveStepperLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollableContent: UIView!
    
    @IBOutlet weak var drawingCollectionView: UICollectionView!
    
    let drawingImages = [ UIImage(named: "drawing1"), UIImage(named: "drawing2"), UIImage(named: "drawing3") ]

    let DEFAULT_IP = "192.168.0.102"
    let DEFAULT_WIFI = "TP-LINK_783C"
    
    var moveDistance = 0
    
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
        
        let ip = UserDefaults.standard.string(forKey: "ip") ?? DEFAULT_IP
        let wifi = UserDefaults.standard.string(forKey: "wifi") ?? DEFAULT_WIFI

        ipAddressField.text = ip
        wifiField.text = wifi
        
        mqttClient = CocoaMQTT(clientID: "iOS Device", host: ip, port: 6667)
        isConnected = false
        
        self.hideKeyboardWhenTappedAround()
        mqttClient.delegate = self
        
        cameraContainerView.addSubview((appDelegate.videoViewController?.view)!)
        
        let scrollSize = CGSize(width: scrollView.frame.size.width,
                                height: scrollableContent.frame.size.height)
        scrollableContent.frame.size = scrollSize
        
        drawingCollectionView.delegate = self
        drawingCollectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mqttClient.ping()
        isConnected = false
    }

    @IBAction func connect(_ sender: Any) {
        
        let ip = ipAddressField.text ?? DEFAULT_IP
        mqttClient.disconnect()
        mqttClient.host = ip
        mqttClient.connect()
        
        let wifi = wifiField.text ?? "Mariuss iPhone"
        
        UserDefaults.standard.set(ip, forKey: "ip")
        UserDefaults.standard.set(wifi, forKey: "wifi")

        
        //let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        //appDelegate.videoViewController = storyboard.instantiateViewController(withIdentifier: "VideoScene") as? VideoViewController
        appDelegate.videoViewController?.stop()
        appDelegate.cameras = [Camera.init("Raspberry", wifi, ip, 5001)]
        appDelegate.videoViewController?.camera = appDelegate.cameras[0]
        appDelegate.videoViewController?.start()
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
    
    @IBAction func sendUp(_ sender: Any) {
        mqttClient.publish("chalk", withString: "up")
    }
    
    @IBAction func sendDown(_ sender: Any) {
        mqttClient.publish("chalk", withString: "down")
    }
    
    @IBAction func sendTurboUp(_ sender: Any) {
        mqttClient.publish("chalk", withString: "turboup")
    }
    
    @IBAction func sendTurboDown(_ sender: Any) {
        mqttClient.publish("chalk", withString: "turbodown")
    }
    
    @IBAction func sendMoveUp(_ sender: Any) {
        let string = "up " + String(moveDistance)
        mqttClient.publish("move", withString: string)
    }
    
    @IBAction func sendMoveDown(_ sender: Any) {
        let string = "down " + String(moveDistance)
        mqttClient.publish("move", withString: string)
    }
    
    @IBAction func sendMoveLeft(_ sender: Any) {
        let string = "left " + String(moveDistance)
        mqttClient.publish("move", withString: string)
    }
    
    @IBAction func sendMoveRight(_ sender: Any) {
        let string = "right " + String(moveDistance)
        mqttClient.publish("move", withString: string)
    }
    
    @IBAction func moveStepper(_ sender: UIStepper) {
        moveDistance = Int(sender.value)
        moveStepperLabel.text = Int(sender.value).description + " cm"
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
    
    @IBAction func drawFlower(_ sender: Any) {
        mqttClient.publish("draw", withString: "flower")
    }
    
    @IBAction func pauseButton(_ sender: Any) {
        mqttClient.publish("control", withString: "pause")
    }
    
    @IBAction func stopButton(_ sender: Any) {
        mqttClient.publish("control", withString: "stop")
    }
    
    func setUI(for connected: Bool) {
        if connected {
            disconnectBtn.isEnabled = true
            disconnectBtn.alpha = 1.0
            gocdeTxt.isEnabled = true
            gocdeTxt.alpha = 1.0
            sendBtn.isEnabled = true
            sendBtn.alpha = 1.0
            upButton.isEnabled = true
            upButton.alpha = 1.0
            turboUpButton.isEnabled = true
            turboUpButton.alpha = 1.0
            downButton.isEnabled = true
            downButton.alpha = 1.0
            turboDownButton.isEnabled = true
            turboDownButton.alpha = 1.0
            shutdownBtn.isEnabled = true
            shutdownBtn.alpha = 1.0
            rebootBtn.isEnabled = true
            rebootBtn.alpha = 1.0
            pauseButton.isEnabled = true
            pauseButton.alpha = 1.0
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
            moveUpButton.isEnabled = true
            moveUpButton.alpha = 1.0
            moveDownButton.isEnabled = true
            moveDownButton.alpha = 1.0
            moveLeftButton.isEnabled = true
            moveLeftButton.alpha = 1.0
            moveRightButton.isEnabled = true
            moveRightButton.alpha = 1.0
            moveStepper.isEnabled = true
            moveStepper.alpha = 1.0
            moveStepperLabel.isEnabled = true
            moveStepperLabel.alpha = 1.0
        } else {
            disconnectBtn.isEnabled = false
            disconnectBtn.alpha = 0.5
            gocdeTxt.isEnabled = false
            gocdeTxt.alpha = 0.5
            sendBtn.isEnabled = false
            sendBtn.alpha = 0.5
            upButton.isEnabled = false
            upButton.alpha = 0.5
            turboUpButton.isEnabled = false
            turboUpButton.alpha = 0.5
            downButton.isEnabled = false
            downButton.alpha = 0.5
            turboDownButton.isEnabled = false
            turboDownButton.alpha = 0.5
            shutdownBtn.isEnabled = false
            shutdownBtn.alpha = 0.5
            rebootBtn.isEnabled = false
            rebootBtn.alpha = 0.5
            pauseButton.isEnabled = false
            pauseButton.alpha = 0.5
            stopButton.isEnabled = false
            stopButton.alpha = 0.5
            moveUpButton.isEnabled = false
            moveUpButton.alpha = 0.5
            moveDownButton.isEnabled = false
            moveDownButton.alpha = 0.5
            moveLeftButton.isEnabled = false
            moveLeftButton.alpha = 0.5
            moveRightButton.isEnabled = false
            moveRightButton.alpha = 0.5
            moveStepper.isEnabled = false
            moveStepper.alpha = 0.5
            moveStepperLabel.isEnabled = false
            moveStepperLabel.alpha = 0.5
        }
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drawingImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:DrawingCell =
            drawingCollectionView.dequeueReusableCell(withReuseIdentifier: "DrawingCell", for: indexPath) as! DrawingCell
        
        cell.initCellItem(with: drawingImages[indexPath.row]!)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let number = String(indexPath.row+1)
        mqttClient.publish("draw", withString: number)

    }
    
    
}
