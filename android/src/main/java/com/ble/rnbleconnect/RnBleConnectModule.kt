package com.ble.rnbleconnect

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.ParcelUuid
import android.util.Log
import androidx.core.app.ActivityCompat
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.util.*

class RnBleConnectModule : Module() {
  private var name: String = "RN_BLE"
  private val TAG = "RnBleConnectModule"
  private val servicesMap = mutableMapOf<String, BluetoothGattService>()
//  private lateinit var context: Context
  private val context
  get() = requireNotNull(appContext.reactContext)
  private lateinit var mBluetoothManager: BluetoothManager
  private lateinit var mBluetoothAdapter: BluetoothAdapter
  private lateinit var mGattServer: BluetoothGattServer
  private lateinit var advertiser: BluetoothLeAdvertiser
  private var advertising = false
  private val mBluetoothDevices = mutableSetOf<BluetoothDevice>()

  private val mGattServerCallback = object : BluetoothGattServerCallback() {
    override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
      super.onConnectionStateChange(device, status, newState)
      if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Bluetooth connect permission not granted")
        return
      }
      if (status == BluetoothGatt.GATT_SUCCESS) {
        if (newState == BluetoothGatt.STATE_CONNECTED) {
          Log.d(TAG, "Device connected: ${device.address}")
          mBluetoothDevices.add(device)
        } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
          Log.d(TAG, "Device disconnected: ${device.address}")
          mBluetoothDevices.remove(device)
        }
      } else {
        Log.d(TAG, "Error in connection state change: $status")
        mBluetoothDevices.remove(device)
      }
    }

    override fun onCharacteristicReadRequest(
      device: BluetoothDevice,
      requestId: Int,
      offset: Int,
      characteristic: BluetoothGattCharacteristic
    ) {
      super.onCharacteristicReadRequest(device, requestId, offset, characteristic)
      if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Bluetooth connect permission not granted")
        return
      }
      if (offset != 0) {
        mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset, null)
        return
      }
      mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.value)
    }

    override fun onCharacteristicWriteRequest(
      device: BluetoothDevice,
      requestId: Int,
      characteristic: BluetoothGattCharacteristic,
      preparedWrite: Boolean,
      responseNeeded: Boolean,
      offset: Int,
      value: ByteArray
    ) {
      super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value)
      if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Bluetooth connect permission not granted")
        return
      }
      characteristic.value = value
      if (responseNeeded) {
        mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
      }
    }

    override fun onNotificationSent(device: BluetoothDevice, status: Int) {
      super.onNotificationSent(device, status)
      Log.d(TAG, "Notification sent to ${device.address} with status: $status")
    }
  }

  init {
    Log.d(TAG, "Welcome to RnBleConnectModule")
  }

  override fun definition() = ModuleDefinition {
    Name("RnBleConnect")

    Function("setName") { newName: String ->
      name = newName
      Log.d(TAG, "Name set to $name")
    }

    Function("getName") {
      Log.d(TAG, "Getting name: $name")
      name
    }

    Function("addService") { uuid: String, primary: Boolean ->
      val serviceUUID = UUID.fromString(uuid)
      val type = if (primary) BluetoothGattService.SERVICE_TYPE_PRIMARY else BluetoothGattService.SERVICE_TYPE_SECONDARY
      val service = BluetoothGattService(serviceUUID, type)
      if (!servicesMap.containsKey(uuid)) {
        servicesMap[uuid] = service
        Log.d(TAG, "Service added with UUID: $uuid")
      } else {
        Log.d(TAG, "Service with UUID: $uuid already exists")
      }
    }

    Function("addCharacteristicToService") { serviceUUID: String, charUUID: String, permissions: Int, properties: Int, characteristicData: String? ->
      val service = servicesMap[serviceUUID]
      if (service != null) {
        val characteristicUUID = UUID.fromString(charUUID)
        val existingCharacteristic = service.getCharacteristic(characteristicUUID)
        if (existingCharacteristic != null) {
          if (!characteristicData.isNullOrEmpty()) {
            existingCharacteristic.value = characteristicData.toByteArray()
          }
        } else {
          val tempChar = BluetoothGattCharacteristic(characteristicUUID, properties, permissions)
          if (!characteristicData.isNullOrEmpty()) {
            tempChar.value = characteristicData.toByteArray()
          }
          service.addCharacteristic(tempChar)
        }
        Log.d(TAG, "Characteristic added or updated in service with UUID: $serviceUUID")
      } else {
        Log.d(TAG, "Service with UUID: $serviceUUID not found")
      }
    }


    AsyncFunction("start") { promise: Promise ->
      mBluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
      mBluetoothAdapter = mBluetoothManager.adapter
      if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Bluetooth connect permission not granted")
        promise.reject("Permission Error", "Bluetooth connect permission not granted", null)
        return@AsyncFunction
      }
      mBluetoothAdapter.name = name

      mBluetoothDevices.clear()
      mGattServer = mBluetoothManager.openGattServer(context, mGattServerCallback)
      for (service in servicesMap.values) {
        mGattServer.addService(service)
      }

      advertiser = mBluetoothAdapter.bluetoothLeAdvertiser
      val settings = AdvertiseSettings.Builder()
        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
        .setConnectable(true)
        .build()

      val dataBuilder = AdvertiseData.Builder()
        .setIncludeDeviceName(true)
      for (service in servicesMap.values) {
        dataBuilder.addServiceUuid(ParcelUuid(service.uuid))
      }
      val data = dataBuilder.build()
      Log.d(TAG, data.toString())

      val advertisingCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
          super.onStartSuccess(settingsInEffect)
          advertising = true
          promise.resolve("Success, Started Advertising")
        }

        override fun onStartFailure(errorCode: Int) {
          advertising = false
          Log.e(TAG, "Advertising onStartFailure: $errorCode")
          promise.reject("Advertising Error", "Advertising onStartFailure: $errorCode", null)
          super.onStartFailure(errorCode)
        }
      }

      advertiser.startAdvertising(settings, data, advertisingCallback)
    }

    AsyncFunction("stop") { promise: Promise ->
      try {
        if (::advertiser.isInitialized) {
          advertiser.stopAdvertising(object : AdvertiseCallback() {
            override fun onStartFailure(errorCode: Int) {
              Log.e(TAG, "Advertising stop failed: $errorCode")
            }

            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
              Log.d(TAG, "Advertising stopped successfully")
            }
          })
        }
        if (::mGattServer.isInitialized) {
          mGattServer.close()
        }
        advertising = false
        promise.resolve("Success, Stopped Advertising")
      } catch (e: Exception) {
        Log.e(TAG, "Error stopping advertising: ${e.message}")
        promise.reject("StopError", "Error stopping advertising: ${e.message}", e)
      }
    }

    Function("sendNotificationToDevices") { serviceUUID: String, charUUID: String, message: List<Int> ->
      val decoded = ByteArray(message.size)
      for (i in message.indices) {
        decoded[i] = message[i].toByte()
      }
      val service = servicesMap[serviceUUID]
      val characteristic = service?.getCharacteristic(UUID.fromString(charUUID))
      if (characteristic != null) {
        characteristic.value = decoded
        val indicate = (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE) == BluetoothGattCharacteristic.PROPERTY_INDICATE
        for (device in mBluetoothDevices) {
          mGattServer.notifyCharacteristicChanged(device, characteristic, indicate)
        }
        Log.d(TAG, "Notification sent to devices")
      } else {
        Log.d(TAG, "Characteristic not found")
      }
    }

    Function("isAdvertising") {
      advertising
    }
  }
}
