# rn-ble-connect

This module let users connect with BLE devices and create own devices as BLE peripheral in React Native Expo.

# API documentation

- [Documentation for the main branch](https://github.com/expo/expo/blob/main/docs/pages/versions/unversioned/sdk/rn-ble-connect.md)
- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/rn-ble-connect/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install rn-ble-connect
```

## Configure for iOS

Run `npx pod-install` after installing the npm package.

### Add bluetooth permissions in IOS info.plist


## Configure for Android

### Add bluetooth permissions in Android
* In `AndroidManifest.xml` add:
```xml
 <uses-permission android:name="android.permission.BLUETOOTH"/>
 <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
```


## Usage

#### Import

```javascript
import * as RnBleConnect from "rn-ble-connect";
```

#### Set name (optional)
RnBleConnect.setName(name:string): void;
This method sets the name of the device broadcast, before calling `start`.

```javascript
RnBleConnect.setName('BLE_PERIPHERAL_NAME')
```

#### Get Name
RnBleConnect.getName(): string;

```javascript
const peripheralName = RnBleConnect.getName()
```

#### Add Service 
RnBleConnect.addService(UUID: string, primary: boolean): void;
```javascript
RnBleConnect.addService('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', true) //for primary service
RnBleConnect.addService('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', false) //for non primary service
```
#### Add Characteristic
RnBleConnect.addCharacteristicToService(ServiceUUID:string, UUID:string, permissions:number, properties:number, characteristicData?: string): void;

```javascript
RnBleConnect.addCharacteristicToService('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 16 | 1, 8) //this is a Characteristic with read and write permissions and notify property
```

#### Characteristic Properties and Permissions for Adnroid
https://developer.android.com/reference/android/bluetooth/BluetoothGattCharacteristic.html
the link above is for permissions and properties constants info

Permissions:
* 1 - Readable
* 2 - Readable Encrypted
* 4 - Readable Encrypted MITM (Man-in-the-middle) Protection 
* 16 - Writable
* 32 - Writable Encrypted
* 64 - Writable Encrypted MITM Protection
* 128 - Writable Signed
* 256 - Writable Signed MITM

Properties:
* 1 - Broadcastable
* 2 - Readable
* 4 - Writable without response
* 8 - Writable
* 16 - Supports notification
* 32 - Supports indication
* 64 - Signed Write
* 128 - Extended properties

#### Characteristic Properties and Permissions for IOS
Permissions:
* 1 - Readable
* 2 - Writable
* 4 - Readable Encrypted
* 8 - Writable Encrypted

Properties:
* 1 - Broadcastable
* 2 - Readable
* 4 - Writable without response
* 8 - Writable
* 10 - Supports notification
* 20 - Supports indication
* 40 - Signed Write
* 80 - Extended properties
* 100 - Notification Encrypted
* 200 - Indication Encrypted

#### Notify to devices
RnBleConnect.sendNotificationToDevices(ServiceUUID:string, CharacteristicUUID:string, data:byte[]) 
- note #1: in js it's not really a byte array, but an array of numbers
- note #2: the CharacteristicUUID must be of a Characteristic with notify property
```javascript
RnBleConnect.sendNotificationToDevices('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', [0x10,0x01,0xA1,0x80]) //sends a notification to all connected devices that, using the char uuid given
```

#### start Advertising 
RnBleConnect.start(): Promise<boolean>;
note:use this only after adding services and characteristics

```javascript
 RnBleConnect.start()
  .then(res => {
       console.log(res)
  }).catch(error => {
       console.log(error)
  })
```

In case of error, these are the error codes:
* 1 - Failed to start advertising as the advertise data to be broadcasted is larger than 31 bytes.
* 2 - Failed to start advertising because no advertising instance is available.
* 3 - Failed to start advertising as the advertising is already started.
* 4 - Operation failed due to an internal error.
* 5 - This feature is not supported on this platform.

#### stop Advertising 
RnBleConnect.stop(): void;

```javascript
 RnBleConnect.stop()
```
