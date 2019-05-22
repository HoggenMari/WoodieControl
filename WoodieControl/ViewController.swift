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
import MaterialComponents

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
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var lightButton: UIButton!
    @IBOutlet weak var guidanceButton: UIButton!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var usageMinLabel: UILabel!
    @IBOutlet weak var idleBg: UIView!
    @IBOutlet weak var drawingBg: UIView!
    @IBOutlet weak var idleLabel: UILabel!
    @IBOutlet weak var drawingLabel: UILabel!
    @IBOutlet weak var idleMinLabel: UILabel!
    @IBOutlet weak var drawingMinLabel: UILabel!
    @IBOutlet weak var batteryChangedButton: UIButton!
    @IBOutlet weak var shockLabel: UILabel!
    @IBOutlet weak var shockView: UIView!
    @IBOutlet weak var detectionLabel: UILabel!
    @IBOutlet weak var detectionSwitch: UISwitch!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollableContent: UIView!
    
    @IBOutlet weak var drawingCollectionView: UICollectionView!
    @IBOutlet weak var lightPatternCollectionView: UICollectionView!
    
    let drawingImages = [ UIImage(named: "drawing1"), UIImage(named: "drawing2"), UIImage(named: "drawing3"), UIImage(named: "drawing4"), UIImage(named: "drawing5"), UIImage(named: "drawing6"), UIImage(named: "drawing7") ]

    let DEFAULT_IP = "192.168.0.102"
    let DEFAULT_WIFI = "TP-LINK_783C"
    
    var moveDistance = 0
    
    var pV: MDCProgressView!
    
    let alphaButton: CGFloat = 0.3
    
    var movingTimeStamp: Double = 0
    var idleTimeStamp: Double = 0
    
    var isIdle = true
    
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
        var timestamp = UserDefaults.standard.double(forKey: "timestamp") ?? NSDate().timeIntervalSince1970
        
        if (timestamp == 0) {
            timestamp = NSDate().timeIntervalSince1970
            UserDefaults.standard.set(timestamp, forKey: "timestamp")
        }
        
        let currentTimeStamp = NSDate().timeIntervalSince1970
        idleTimeStamp = currentTimeStamp
        
        let time = secondsToHoursMinutesSeconds(seconds: (Int)(currentTimeStamp - timestamp))
        
        
        ipAddressField.text = ip
        wifiField.text = wifi
        //usageMinLabel.text = String(time.0)+"h "+String(time.1)+"min"
        
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
        
        pV = MDCProgressView()
        pV.progress = 0.0
        pV.backgroundColor = .clear
        pV.trackTintColor = .white
        pV.progressTintColor = .purple
        
        
        let pVHeight = CGFloat(20)
        pV.frame = CGRect(x: 0, y: progressView.bounds.height - pVHeight, width: progressView.bounds.width, height: pVHeight)
        progressView.addSubview(pV)
        
        let timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        updateTime()
        
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
        
        //mqttClient.subscribe("drawingstatus")

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
        
        if ack == .accept {
            mqtt.subscribe("drawingstatus", qos: CocoaMQTTQOS.qos1)
            mqtt.subscribe("status", qos: CocoaMQTTQOS.qos1)
            mqtt.subscribe("shock", qos: CocoaMQTTQOS.qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didReceiveMessage")
        
        if (message.topic == "drawingstatus") {
            let percent = Float(message.string!)
            pV.progress = percent ?? 0.0
            print(message.topic)
        } else if (message.topic == "status") {
            let status = message.string
            if (status=="DRAWING" || status=="JOGGING") {
                if (status=="DRAWING") {
                    drawingCollectionView.alpha = alphaButton
                }
                let currentTimeStamp = NSDate().timeIntervalSince1970
                movingTimeStamp = currentTimeStamp
                let addIdleTime = (Int)(currentTimeStamp - idleTimeStamp)
                let totalIdleTime = UserDefaults.standard.integer(forKey: "idletimestamp") ?? 0 + addIdleTime
                UserDefaults.standard.set(totalIdleTime, forKey: "idletimestamp")
                isIdle = false
                updateTime()
                
            } else if (status=="IDLE") {
                drawingCollectionView.alpha = 1.0
                let currentTimeStamp = NSDate().timeIntervalSince1970
                idleTimeStamp = currentTimeStamp
                let addMovingTime = (Int)(currentTimeStamp - movingTimeStamp)
                let totalMovingTime = UserDefaults.standard.integer(forKey: "movingtimestamp") ?? 0 + addMovingTime
                UserDefaults.standard.set(totalMovingTime, forKey: "movingtimestamp")
                isIdle = true
                updateTime()
            }
        } else if (message.topic == "shock") {
            let str = message.string
            if (str=="alarm") {
                resumeButton.backgroundColor = .green
            } else {
                animateView(shockView)
            }
        }
    }
    
    fileprivate func animateView(_ view: UIView) {
        
        view.backgroundColor = UIColor.white
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
            view.backgroundColor = UIColor.red
        }, completion: { [weak self] finished in
            view.backgroundColor = UIColor.white
        })
        
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
        //isConnected = true
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
        resumeButton.backgroundColor = UIColor.green
    }
    
    @IBAction func stopButton(_ sender: Any) {
        mqttClient.publish("control", withString: "stop")
    }
    
    @IBAction func resumeButton(_ sender: Any) {
        mqttClient.publish("control", withString: "resume")
        resumeButton.backgroundColor = UIColor.init(red: 0.42, green: 0.42, blue: 0.42, alpha: 1)
    }
    
    @IBAction func lightsOnButton(_ sender: Any) {
        mqttClient.publish("lightcontrol", withString: "togglelight")
    }
    
    @IBAction func guidanceOnButton(_ sender: Any) {
        mqttClient.publish("lightcontrol", withString: "toggleguidance")
    }
    
    @IBAction func brightnessChanged(_ sender: UISlider) {
        let string = "brightness " + String(sender.value)
        mqttClient.publish("lightcontrol", withString: string)
    }
    
    @IBAction func batteryWasChanged(_ sender: Any) {
        
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to reset the battery counter?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.resetBatteryCounter()
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
        
    }
    
    func resetBatteryCounter() {
        let timestamp = NSDate().timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: "timestamp")
        UserDefaults.standard.set(0, forKey: "idletimestamp")
        UserDefaults.standard.set(0, forKey: "movingtimestamp")

        idleTimeStamp = timestamp
        
        updateTime()
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
    @objc func updateTime()
    {
        let timestamp = UserDefaults.standard.double(forKey: "timestamp")
        
        let currentTimeStamp = NSDate().timeIntervalSince1970
        
        let time = secondsToHoursMinutesSeconds(seconds: (Int)(currentTimeStamp - timestamp))
        
        usageMinLabel.text = String(time.0)+"h "+String(time.1)+"min"
        
        var idletimestamp = 0
        if (isIdle) {
            let currentTimeStamp = NSDate().timeIntervalSince1970
            let addIdleTime = (Int)(currentTimeStamp - idleTimeStamp)
            idleTimeStamp = currentTimeStamp
            idletimestamp = UserDefaults.standard.integer(forKey: "idletimestamp") + addIdleTime
            UserDefaults.standard.set(idletimestamp, forKey: "idletimestamp")
        } else {
            idletimestamp = UserDefaults.standard.integer(forKey: "idletimestamp")
        }
        let idletimestamptupel = secondsToHoursMinutesSeconds(seconds: idletimestamp)
        
        idleMinLabel.text = String(idletimestamptupel.0)+"h "+String(idletimestamptupel.1)+"min"
        
        var movingtimestamp = 0
        if (!isIdle) {
            let currentTimeStamp = NSDate().timeIntervalSince1970
            let addMovingTime = (Int)(currentTimeStamp - movingTimeStamp)
            movingTimeStamp = currentTimeStamp
            movingtimestamp = UserDefaults.standard.integer(forKey: "movingtimestamp") + addMovingTime
            UserDefaults.standard.set(movingtimestamp, forKey: "movingtimestamp")

        } else {
            movingtimestamp = UserDefaults.standard.integer(forKey: "movingtimestamp")
        }
        
        let movingtimestamptupel = secondsToHoursMinutesSeconds(seconds: movingtimestamp)
        
        drawingMinLabel.text = String(movingtimestamptupel.0)+"h "+String(movingtimestamptupel.1)+"min"
        
    }
    
    @IBAction func detectionSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            mqttClient.publish("control", withString: "detection on")
        } else {
            mqttClient.publish("control", withString: "detection off")
        }
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
            lightButton.isEnabled = true
            lightButton.alpha = 1.0
            guidanceButton.isEnabled = true
            guidanceButton.alpha = 1.0
            resumeButton.isEnabled = true
            resumeButton.alpha = 1.0
            cameraContainerView.alpha = 1.0
            drawingCollectionView.alpha = 1.0
            lightPatternCollectionView.alpha = 1.0
            lightPatternCollectionView.allowsSelection = true
            drawingCollectionView.allowsSelection = true
            progressView.alpha = 1.0
            brightnessSlider.alpha = 1.0
            brightnessSlider.isEnabled = true
            brightnessLabel.alpha = 1.0
            brightnessLabel.isEnabled = true
            usageLabel.alpha = 1.0
            usageLabel.isEnabled = true
            usageMinLabel.alpha = 1.0
            usageMinLabel.isEnabled = true
            idleBg.alpha = 0.8
            drawingBg.alpha = 0.8
            idleLabel.alpha = 1.0
            idleLabel.isEnabled = true
            drawingLabel.alpha = 1.0
            drawingLabel.isEnabled = true
            idleMinLabel.alpha = 1.0
            idleMinLabel.isEnabled = true
            drawingMinLabel.alpha = 1.0
            drawingMinLabel.isEnabled = true
            shockLabel.alpha = 1.0
            shockLabel.isEnabled = true
            shockView.alpha = 1.0
            detectionLabel.alpha = 1.0
            detectionLabel.isEnabled = true
            detectionSwitch.alpha = 1.0
            detectionSwitch.isEnabled = true
            //batteryChangedButton.alpha = 1.0
            //batteryChangedButton.isEnabled = true
        } else {
            disconnectBtn.isEnabled = false
            disconnectBtn.alpha = alphaButton
            gocdeTxt.isEnabled = false
            gocdeTxt.alpha = alphaButton
            sendBtn.isEnabled = false
            sendBtn.alpha = alphaButton
            upButton.isEnabled = false
            upButton.alpha = alphaButton
            turboUpButton.isEnabled = false
            turboUpButton.alpha = alphaButton
            downButton.isEnabled = false
            downButton.alpha = alphaButton
            turboDownButton.isEnabled = false
            turboDownButton.alpha = alphaButton
            shutdownBtn.isEnabled = false
            shutdownBtn.alpha = alphaButton
            rebootBtn.isEnabled = false
            rebootBtn.alpha = alphaButton
            pauseButton.isEnabled = false
            pauseButton.alpha = alphaButton
            stopButton.isEnabled = false
            stopButton.alpha = alphaButton
            moveUpButton.isEnabled = false
            moveUpButton.alpha = alphaButton
            moveDownButton.isEnabled = false
            moveDownButton.alpha = alphaButton
            moveLeftButton.isEnabled = false
            moveLeftButton.alpha = alphaButton
            moveRightButton.isEnabled = false
            moveRightButton.alpha = alphaButton
            moveStepper.isEnabled = false
            moveStepper.alpha = alphaButton
            moveStepperLabel.isEnabled = false
            moveStepperLabel.alpha = alphaButton
            lightButton.isEnabled = false
            lightButton.alpha = alphaButton
            guidanceButton.isEnabled = false
            guidanceButton.alpha = alphaButton
            resumeButton.isEnabled = false
            resumeButton.alpha = alphaButton
            cameraContainerView.alpha = alphaButton
            drawingCollectionView.alpha = alphaButton
            lightPatternCollectionView.alpha = alphaButton
            lightPatternCollectionView.allowsSelection = false
            drawingCollectionView.allowsSelection = false
            progressView.alpha = alphaButton
            brightnessSlider.alpha = alphaButton
            brightnessSlider.isEnabled = false
            brightnessLabel.alpha = alphaButton
            brightnessLabel.isEnabled = false
            usageLabel.alpha = alphaButton
            usageLabel.isEnabled = false
            usageMinLabel.alpha = alphaButton
            usageMinLabel.isEnabled = false
            idleBg.alpha = alphaButton
            drawingBg.alpha = alphaButton
            idleLabel.alpha = alphaButton
            idleLabel.isEnabled = false
            drawingLabel.alpha = alphaButton
            drawingLabel.isEnabled = false
            idleMinLabel.alpha = alphaButton
            idleMinLabel.isEnabled = false
            drawingMinLabel.alpha = alphaButton
            drawingMinLabel.isEnabled = false
            shockLabel.alpha = alphaButton
            shockLabel.isEnabled = false
            shockView.alpha = alphaButton
            detectionLabel.alpha = alphaButton
            detectionLabel.isEnabled = false
            detectionSwitch.alpha = alphaButton
            detectionSwitch.isEnabled = false
            //batteryChangedButton.alpha = alphaButton
            //batteryChangedButton.isEnabled = false
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
