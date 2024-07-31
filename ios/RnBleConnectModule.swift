import ExpoModulesCore
import CoreBluetooth

public class RnBleConnectModule: Module {
  public func definition() -> ModuleDefinition {
    Name("RnBleConnect")
    
    var ble = BLEPeripheral();

    // Events("onWarning")

    // func sendBLEEvent(eventName: String, body: Any) {
    //   sendEvent(eventName, body)
    // }
    
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

    Function("addCharacteristicToService") { (serviceUUID: String, uuid: String, permissions: UInt, properties: UInt, data: String) -> Void in
      return ble.addCharacteristicToService(serviceUUID, uuid:uuid, permissions:permissions, properties:properties, data:data)
    }

    Function("start") {
      return ble.start()
    }

    Function("stop") {
      return ble.stop()
    }

    Function("sendNotificationToDevices") { (serviceUUID: String, characteristicUUID: String, data: Data) -> Void in
      return ble.sendNotificationToDevices(serviceUUID, characteristicUUID:characteristicUUID, data:data)
    }
  }
}
