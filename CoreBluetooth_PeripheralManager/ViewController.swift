//
//  ViewController.swift
//  CoreBluetooth_PeripheralManager
//
//  Created by Alain Hsu on 2021/3/12.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate{
    let kServiceUuid = "94515FA0-D9DD-41D4-9D2C-CA3CFFF6C83D"
    let kCharacteristicUUID = "94515FA1-D9DD-41D4-9D2C-CA3CFFF6C83D"
    let kCharacteristicUUID2 = "94515FA2-D9DD-41D4-9D2C-CA3CFFF6C83D"

    var service : CBMutableService?
    var peripheralManager: CBPeripheralManager?
    
    var myValue = "123"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState \(peripheral.state.rawValue)")

        if peripheral.state == .poweredOn {
            let serviceUuid = CBUUID(string: kServiceUuid)
            self.service = CBMutableService(type: serviceUuid, primary: true)
            
            let readWriteChar = CBMutableCharacteristic.init(
                type: CBUUID(string: kCharacteristicUUID),
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [.readable, .writeable])
            let encryptedChar = CBMutableCharacteristic.init(
                type: CBUUID(string: kCharacteristicUUID2),
                properties: [.read, .notify, .notifyEncryptionRequired],
                value: nil,
                permissions: [.readable])
            
            service?.characteristics = []
            service?.characteristics?.append(readWriteChar)
            service?.characteristics?.append(encryptedChar)

            peripheralManager?.add(service!)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
           print("Add service failed: \(error.localizedDescription)")
           return
        }
        print("Add service succeeded")
        
        peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey: "HAHAHA",
                                            CBAdvertisementDataServiceUUIDsKey : [self.service!.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Start advertising failed: \(error.localizedDescription)")
            return
        }
        print("Start advertising succeeded")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Read request")
        request.value = myValue.data(using: .utf8)
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Write request")
        if let data = requests[0].value {
            myValue = String(decoding: data, as: UTF8.self)

        }
        peripheral.respond(to: requests[0], withResult: .success)
    }
}
