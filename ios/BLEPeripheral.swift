import Foundation
import CoreBluetooth
import ExpoModulesCore

class BLEPeripheral: NSObject, CBPeripheralManagerDelegate {
    var advertising: Bool = false
    var name: String?
    var servicesMap = Dictionary<String, CBMutableService>()
    var module: RnBleConnectModule!
    var manager: CBPeripheralManager!
    var startPromiseResolve: EXPromiseResolveBlock?
    var startPromiseReject: EXPromiseRejectBlock?
    
    init(bleModule: RnBleConnectModule) {
        super.init()
        module = bleModule
        manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        advertising = false
        name = "RN_BLE"
        alertJS("BLEPeripheral initialized, advertising: \(advertising)")
    }

    func setName(_ name: String) {
        self.name = name
        alertJS("peripheral name set to \(name)")
    }

    func getName() -> String {
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
            alertJS("added service \(uuid)")
        } else {
            alertJS("service \(uuid) already there")
        }
    }
    
    func addCharacteristicToService(_ serviceUUID: String, uuid: String, permissions: UInt, properties: UInt, data: String? = nil) {
        let characteristicUUID = CBUUID(string: uuid)
        let propertyValue = CBCharacteristicProperties(rawValue: properties)
        let permissionValue = CBAttributePermissions(rawValue: permissions)
        let characteristic: CBMutableCharacteristic;
        if(data != nil) {
            let byteData: Data = data!.data(using: .utf8)!
            characteristic = CBMutableCharacteristic( type: characteristicUUID, properties: propertyValue, value: byteData, permissions: permissionValue)
        } else {
            characteristic = CBMutableCharacteristic( type: characteristicUUID, properties: propertyValue, value: nil, permissions: permissionValue)
        }
        
        if(servicesMap[serviceUUID] != nil) {
            if(servicesMap[serviceUUID]!.characteristics != nil) {
                servicesMap[serviceUUID]!.characteristics!.append(characteristic)
            } else {
                servicesMap[serviceUUID]!.characteristics = [characteristic]
            }
        }
        
        alertJS("added characteristic to service")
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
       
       alertJS("starting advertising")
       manager.startAdvertising(advertisementData)
   }
    
    func stop() {
        manager.removeAllServices()
        manager.stopAdvertising()
        advertising = false
        alertJS("Advertisement Stopped")
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
                alertJS("changed data for characteristic \(characteristicUUID)")
            } else {
                alertJS("failed to send changed data for characteristic \(characteristicUUID)")
            }

        } else {
            alertJS("service \(serviceUUID) does not exist")
        }
    }
    
    //// EVENTS
    // Respond to Read request
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest)
    {
        alertJS("characteristic read request received")
        let characteristic = getCharacteristic(request.characteristic.uuid)
        if (characteristic != nil){
            request.value = characteristic?.value
            manager.respond(to: request, withResult: .success)
        } else {
            alertJS("cannot read, characteristic not found")
        }
    }

    // Respond to Write request
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        alertJS("characteristic write request received")
        for request in requests
        {
            let characteristic = getCharacteristic(request.characteristic.uuid)
            if (characteristic == nil) { alertJS("characteristic for writing not found") }
            if request.characteristic.uuid.isEqual(characteristic?.uuid)
            {
                let char = characteristic as! CBMutableCharacteristic
                char.value = request.value
                let str = String(decoding: char.value!, as: UTF8.self)
                alertJS("characteristic data received \(str)")
                
                module?.sendBLEEvent(type: module.DATA_RECEIVED_EVENT, data: [
                    "value": str,
                    "device": convertCBCentralToDictionary(central: request.central),
                    "characteristic": convertCBCharacteristicToDictionary(characteristic: char)
                ])
            } else {
                alertJS("characteristic you are trying to access doesn't match")
            }
        }
        manager.respond(to: requests[0], withResult: .success)
    }

    // Respond to Subscription to Notification events
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let char = characteristic as! CBMutableCharacteristic
        alertJS("subscribed centrals: \(String(describing: char.subscribedCentrals))")
    }

    // Respond to Unsubscribe events
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        let char = characteristic as! CBMutableCharacteristic
        alertJS("unsubscribed centrals: \(String(describing: char.subscribedCentrals))")
    }

    // Service added
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            alertJS("error: \(error)")
            return
        }
        alertJS("service: \(service)")
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
        alertJS("advertising succeeded!")
    }
    
    //// HELPERS

    func getCharacteristic(_ characteristicUUID: CBUUID) -> CBCharacteristic? {
        for (uuid, service) in servicesMap {
            for characteristic in service.characteristics ?? [] {
                if (characteristic.uuid.isEqual(characteristicUUID) ) {
                    alertJS("service \(uuid) does have characteristic \(characteristicUUID)")
                    if (characteristic is CBMutableCharacteristic) {
                        return characteristic
                    }
                    alertJS("but it is not mutable")
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
                alertJS("service \(service.uuid) does have characteristic \(characteristicUUID)")
                if (characteristic is CBMutableCharacteristic) {
                    return characteristic
                }
                alertJS("but it is not mutable")
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
        alertJS("service array \(serviceArray)")
        return serviceArray
    }

    func alertJS(_ message: String) {
        print("RNBLEMODULE", message);
        module?.sendBLEEvent(type: module.LOG_EVENT, data: message)
    }
    
    func convertCBCentralToDictionary(central: CBCentral) -> [String: String] {
        var centralInfo = [String: String]()
        
        // Extracting the identifier as a string
        centralInfo["identifier"] = central.identifier.uuidString
        
        // Extracting maximum update value length
        centralInfo["maximumUpdateValueLength"] = "\(central.maximumUpdateValueLength)"
        
        return centralInfo
    }
    
    func convertCBCharacteristicToDictionary(characteristic: CBCharacteristic) -> [String: String] {
        var characteristicInfo = [String: String]()
        
        // Extracting the UUID as a string
        characteristicInfo["uuid"] = characteristic.uuid.uuidString
        
        // Converting the properties to a human-readable string
        characteristicInfo["properties"] = describeProperties(characteristic.properties)
        
        // Extracting the value (if available) as a hexadecimal string
        if let value = characteristic.value {
            characteristicInfo["value"] = String(decoding: value, as: UTF8.self)
        } else {
            characteristicInfo["value"] = "nil"
        }
        
        // Checking if the characteristic is notifying
        characteristicInfo["isNotifying"] = characteristic.isNotifying ? "true" : "false"
        
        return characteristicInfo
    }
    
    func describeProperties(_ properties: CBCharacteristicProperties) -> String {
        var propertyStrings: [String] = []
        
        if properties.contains(.broadcast) {
            propertyStrings.append("Broadcast")
        }
        if properties.contains(.read) {
            propertyStrings.append("Read")
        }
        if properties.contains(.writeWithoutResponse) {
            propertyStrings.append("Write Without Response")
        }
        if properties.contains(.write) {
            propertyStrings.append("Write")
        }
        if properties.contains(.notify) {
            propertyStrings.append("Notify")
        }
        if properties.contains(.indicate) {
            propertyStrings.append("Indicate")
        }
        if properties.contains(.authenticatedSignedWrites) {
            propertyStrings.append("Authenticated Signed Writes")
        }
        if properties.contains(.extendedProperties) {
            propertyStrings.append("Extended Properties")
        }
        if properties.contains(.notifyEncryptionRequired) {
            propertyStrings.append("Notify Encryption Required")
        }
        if properties.contains(.indicateEncryptionRequired) {
            propertyStrings.append("Indicate Encryption Required")
        }
        
        return propertyStrings.joined(separator: ", ")
    }
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
