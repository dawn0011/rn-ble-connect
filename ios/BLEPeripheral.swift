import Foundation
import CoreBluetooth
import ExpoModulesCore

class BLEPeripheral: NSObject, CBPeripheralManagerDelegate {
    var advertising: Bool = false
    var hasListeners: Bool = false
    var name: String?
    var servicesMap = Dictionary<String, CBMutableService>()
    var manager: CBPeripheralManager!
    var startPromiseResolve: EXPromiseResolveBlock?
    var startPromiseReject: EXPromiseRejectBlock?
    
    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        advertising = false
        name = "RN_BLE"
        print("BLEPeripheral initialized, advertising: \(advertising)")
    }

    func setName(_ name: String) {
        self.name = name
        print("peripheral name set to \(name)")
    }

    func getName() -> String{
        return self.name ?? "RN_BLE"
    }
    
    func isAdvertising() -> Bool {
        return advertising
    }
    
    func addService(_ uuid: String, primary: Bool) {
        let serviceUUID = CBUUID(string: uuid)
        let service = CBMutableService(type: serviceUUID, primary: primary)
        if(servicesMap.keys.contains(uuid) != true){
            servicesMap[uuid] = service
            print("added service \(uuid)")
        } else {
            alertJS("service \(uuid) already there")
        }
    }
    
    func addCharacteristicToService(_ serviceUUID: String, uuid: String, permissions: UInt, properties: UInt, data: String) {
        let characteristicUUID = CBUUID(string: uuid)
        let propertyValue = CBCharacteristicProperties(rawValue: properties)
        let permissionValue = CBAttributePermissions(rawValue: permissions)
        let byteData: Data = data.data(using: .utf8)!
        let characteristic = CBMutableCharacteristic( type: characteristicUUID, properties: propertyValue, value: byteData, permissions: permissionValue)
        
        if(servicesMap[serviceUUID] != nil) {
            if(servicesMap[serviceUUID]!.characteristics != nil) {
                servicesMap[serviceUUID]!.characteristics!.append(characteristic)
            } else {
                servicesMap[serviceUUID]!.characteristics = [characteristic]
            }
        }
        
        print("added characteristic to service")
    }
    
   func start(_ resolve: @escaping EXPromiseResolveBlock, rejecter reject: @escaping EXPromiseRejectBlock) {
       if (manager.state != .poweredOn) {
           alertJS("Bluetooth turned off")
           return;
       }
       
       startPromiseResolve = resolve
       startPromiseReject = reject
       
       let advertisementData: [String:Any]
       
       if(self.name != nil) {
           advertisementData = [
                   CBAdvertisementDataLocalNameKey: self.name as Any,
                   CBAdvertisementDataServiceUUIDsKey: getServiceUUIDArray()
               ]
       } else {
           advertisementData = [CBAdvertisementDataServiceUUIDsKey: getServiceUUIDArray()]
       }
       
       for (_, service) in servicesMap {
           manager.add(service)
       }
       
       print("starting advertising")
       manager.startAdvertising(advertisementData)
   }
    
    func stop() {
        manager.removeAllServices()
        manager.stopAdvertising()
        advertising = false
        print("Advertisement Stopped")
    }

    func sendNotificationToDevices(_ serviceUUID: String, characteristicUUID: String, data: Data) {
        if(servicesMap.keys.contains(serviceUUID) == true){
            let service = servicesMap[serviceUUID]!
            let characteristic = getCharacteristicForService(service, characteristicUUID)
            if (characteristic == nil) { alertJS("service \(serviceUUID) does NOT have characteristic \(characteristicUUID)") }

            let char = characteristic as! CBMutableCharacteristic
            char.value = data
            let success = manager.updateValue( data, for: char, onSubscribedCentrals: nil)
            if (success){
                print("changed data for characteristic \(characteristicUUID)")
            } else {
                alertJS("failed to send changed data for characteristic \(characteristicUUID)")
            }

        } else {
            alertJS("service \(serviceUUID) does not exist")
        }
    }
    
    //// EVENTS

    // Respond to Read request
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest)
    {
        let characteristic = getCharacteristic(request.characteristic.uuid)
        if (characteristic != nil){
            request.value = characteristic?.value
            manager.respond(to: request, withResult: .success)
        } else {
            alertJS("cannot read, characteristic not found")
        }
    }

    // Respond to Write request
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest])
    {
        for request in requests
        {
            let characteristic = getCharacteristic(request.characteristic.uuid)
            if (characteristic == nil) { alertJS("characteristic for writing not found") }
            if request.characteristic.uuid.isEqual(characteristic?.uuid)
            {
                let char = characteristic as! CBMutableCharacteristic
                char.value = request.value
            } else {
                alertJS("characteristic you are trying to access doesn't match")
            }
        }
        manager.respond(to: requests[0], withResult: .success)
    }

    // Respond to Subscription to Notification events
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let char = characteristic as! CBMutableCharacteristic
        print("subscribed centrals: \(String(describing: char.subscribedCentrals))")
    }

    // Respond to Unsubscribe events
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        let char = characteristic as! CBMutableCharacteristic
        print("unsubscribed centrals: \(String(describing: char.subscribedCentrals))")
    }

    // Service added
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            alertJS("error: \(error)")
            return
        }
        print("service: \(service)")
    }

    // Bluetooth status changed
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        var state: Any
        if #available(iOS 10.0, *) {
            state = peripheral.state.description
        } else {
            state = peripheral.state
        }
        alertJS("BT state change: \(state)")
    }

    // Advertising started
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            alertJS("advertising failed. error: \(error)")
            advertising = false
            startPromiseReject!("AD_ERR", "advertising failed", error)
            return
        }
        advertising = true
        startPromiseResolve!(advertising)
        print("advertising succeeded!")
    }
    
    //// HELPERS

    func getCharacteristic(_ characteristicUUID: CBUUID) -> CBCharacteristic? {
        for (uuid, service) in servicesMap {
            for characteristic in service.characteristics ?? [] {
                if (characteristic.uuid.isEqual(characteristicUUID) ) {
                    print("service \(uuid) does have characteristic \(characteristicUUID)")
                    if (characteristic is CBMutableCharacteristic) {
                        return characteristic
                    }
                    print("but it is not mutable")
                } else {
                    alertJS("characteristic you are trying to access doesn't match")
                }
            }
        }
        return nil
    }

    func getCharacteristicForService(_ service: CBMutableService, _ characteristicUUID: String) -> CBCharacteristic? {
        for characteristic in service.characteristics ?? [] {
            if (characteristic.uuid.isEqual(characteristicUUID) ) {
                print("service \(service.uuid) does have characteristic \(characteristicUUID)")
                if (characteristic is CBMutableCharacteristic) {
                    return characteristic
                }
                print("but it is not mutable")
            } else {
                alertJS("characteristic you are trying to access doesn't match")
            }
        }
        return nil
    }

    func getServiceUUIDArray() -> Array<CBUUID> {
        var serviceArray = [CBUUID]()
        for (_, service) in servicesMap {
            serviceArray.append(service.uuid)
        }
        print("service array %@", serviceArray)
        return serviceArray
    }

    func alertJS(_ message: Any) {
        print(message)
        if(hasListeners) {
//            sendEvent(withName: "onWarning", body: message)
        }
    }

//    override func supportedEvents() -> [String]! { return ["onWarning"] }
//    override func startObserving() { hasListeners = true }
//    override func stopObserving() { hasListeners = false }
//    override static func requiresMainQueueSetup() -> Bool { return false }
    
}

@available(iOS 10.0, *)
extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .poweredOff: return ".poweredOff"
        case .poweredOn: return ".poweredOn"
        case .resetting: return ".resetting"
        case .unauthorized: return ".unauthorized"
        case .unknown: return ".unknown"
        case .unsupported: return ".unsupported"
        @unknown default:
            return ".unknown"
        }
    }
}
