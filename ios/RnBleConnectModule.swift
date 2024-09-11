import ExpoModulesCore
import CoreBluetooth

public class RnBleConnectModule: Module {
  
  var hasListeners = false
  let LOG_EVENT = "onLog"
  let DATA_RECEIVED_EVENT = "onDataReceived"
    
  public func definition() -> ModuleDefinition {
    Name("RnBleConnect")
      
    Events(LOG_EVENT, DATA_RECEIVED_EVENT)
      
    OnStartObserving {
      hasListeners = true
    }

    OnStopObserving {
      hasListeners = false
    }

    let ble = BLEPeripheral(bleModule: self);
    
    Function("isAdvertising") {
      return ble.isAdvertising()
    }

    Function("setName") { (name: String) -> Void in
      return ble.setName(name)
    }

    Function("getName") {
      return ble.getName()
    }

    Function("addService") { (uuid: String, primary: Bool) -> Void in
      return ble.addService(uuid, primary:primary)
    }

    Function("addCharacteristicToService") { (serviceUUID: String, uuid: String, permissions: UInt, properties: UInt, data: String? ) -> Void in
      return ble.addCharacteristicToService(serviceUUID, uuid:uuid, permissions:permissions, properties:properties, data:data)
    }

    AsyncFunction("start") { (promise: Promise) in
        ble.start(promise.resolver, rejecter: promise.legacyRejecter)
    }

    Function("stop") {
      return ble.stop()
    }

    Function("sendNotificationToDevices") { (serviceUUID: String, characteristicUUID: String, data: Data) -> Void in
      return ble.sendNotificationToDevices(serviceUUID, characteristicUUID:characteristicUUID, data:data)
    }
  }
    
  @objc
  public func sendBLEEvent(type: String, data: Any) {
    print("RNBLEMODULE haslisterns: ", hasListeners);
    if(hasListeners) {
        sendEvent(type, [
            "data": data
        ])
    }
  }
}
