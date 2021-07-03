//
//  ViewController.swift
//  CoreBluetooth_PeripheralManager
//
//  Created by Alain Hsu on 2021/3/12.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate{
    
    // MARK: Initialization
    @IBOutlet weak var intervalTextfield: UITextField!
    @IBOutlet weak var hrTextfield: UITextField!
    @IBOutlet weak var distanceTextfield: UITextField!
    @IBOutlet weak var eiTextfield: UITextField!
    @IBOutlet weak var gearTextfield: UITextField!
    @IBOutlet weak var stTextfield: UITextField!
    @IBOutlet weak var durationTextfield: UITextField!
    @IBOutlet weak var cadenceTextfield: UITextField!
    let service = CBMutableService(type: CBUUID(string: "94515FA0-D9DD-41D4-9D2C-CA3CFFF6C83D"), primary: true)
    let characteristic = CBMutableCharacteristic.init(
        type: CBUUID(string: "94515FA1-D9DD-41D4-9D2C-CA3CFFF6C83D"),
        properties: [.read, .write, .notify],
        value: nil,
        permissions: [.readable, .writeable])
    var peripheralManager: CBPeripheralManager?
    var centrals: [CBCentral]?
    var timer: Timer?
    
    var cadence:Float32 = 72.4
    var duration:Int16 = 38
    var heartRate:Int16 = 123
    var stepsTaken:Int16 = 18
    var distance:Int16 = 12
    var gear:Int16 = 4
    var equipmentId:Int16 = 888
    
    // MARK: - UI Actions
    
    // Hide keyboard
    @IBAction func viewDidTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func startBtnTapped(_ sender: Any) {
        print("start!")
        let interval = (Double(intervalTextfield.text ?? "500") ?? 500) / 1000.0
        print("interval: \(interval)")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [self] timer in
            
            // Set random value
            cadence = cadence + Float32.random(in: -10...10)
            duration = duration + Int16.random(in: 0...1)
            heartRate = heartRate + Int16.random(in: -20...20)
            stepsTaken = stepsTaken + Int16.random(in: 0...2)
            distance = stepsTaken + Int16.random(in: -1...2)
            gear = gear + Int16.random(in: -2...2)
            
            // Convert value to data
            let cadenceData = Data(buffer: UnsafeBufferPointer(start: &cadence, count: 1))
            let durationData = Data(buffer: UnsafeBufferPointer(start: &duration, count: 1))
            let heartRateData = Data(buffer: UnsafeBufferPointer(start: &heartRate, count: 1))
            let stepsTakenData = Data(buffer: UnsafeBufferPointer(start: &stepsTaken, count: 1))
            let distanceData = Data(buffer: UnsafeBufferPointer(start: &distance, count: 1))
            let gearData = Data(buffer: UnsafeBufferPointer(start: &gear, count: 1))
            let equipmentIdData = Data(buffer: UnsafeBufferPointer(start: &equipmentId, count: 1))
            
            var package = cadenceData+durationData+heartRateData+stepsTakenData+distanceData+gearData+equipmentIdData
            let value1 = package[0...3].withUnsafeBytes { $0.load(as: Float32.self) }
            let value2 = package[4...5].withUnsafeBytes { $0.load(as: Int16.self) }
            let value3 = package[6...7].withUnsafeBytes { $0.load(as: Int16.self) }
            let value4 = package[8...9].withUnsafeBytes { $0.load(as: Int16.self) }
            let value5 = package[10...11].withUnsafeBytes { $0.load(as: Int16.self) }
            let value6 = package[12...13].withUnsafeBytes { $0.load(as: Int16.self) }
            let value7 = package[14...15].withUnsafeBytes { $0.load(as: Int16.self) }
            
            // Update UI
            cadenceTextfield.text = String(value1)
            durationTextfield.text = String(value2)
            hrTextfield.text = String(value3)
            stTextfield.text = String(value4)
            distanceTextfield.text = String(value5)
            gearTextfield.text = String(value6)
            eiTextfield.text = String(value7)
            
            // Notify new value to central devices
            peripheralManager?.updateValue(Data(bytes: &package, count: MemoryLayout.size(ofValue:package)), for: characteristic, onSubscribedCentrals: centrals)
        });
    }
    
    @IBAction func stopBtnTapped(_ sender: Any) {
        print("stop!")
        timer?.invalidate()
    }
    
    
    // MARK: - LifeCycle Hooks
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    
    // MARK: - Peripheral Delegates
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState \(peripheral.state.rawValue)")
        
        if peripheral.state == .poweredOn {
            service.characteristics = []
            service.characteristics?.append(characteristic)
            peripheralManager?.add(service)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Add service failed: \(error.localizedDescription)")
            return
        }
        print("Add service succeeded")
        
        peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey: "HAHAHA",
                                             CBAdvertisementDataServiceUUIDsKey : [self.service.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Start advertising failed: \(error.localizedDescription)")
            return
        }
        print("Start advertising succeeded")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("didSubscribeTo \(characteristic.uuid.uuidString)")
        centrals?.append(central)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("didUnsubscribeFrom \(characteristic.uuid.uuidString)")
        centrals?.removeAll()
    }
    
}

extension Data {
    init<T>(value: T) {
        self = withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) -> Data in
            return Data(buffer: UnsafeBufferPointer(start: ptr, count: 1))
        }
    }
    
    mutating func append<T>(value: T) {
        withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) in
            append(UnsafeBufferPointer(start: ptr, count: 1))
        }
    }
}
