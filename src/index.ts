import RnBleConnectModule from "./RnBleConnectModule";
import { Platform } from 'react-native';

export const addService: typeof RnBleConnectModule.addService = RnBleConnectModule.addService;
export const addCharacteristicToService: typeof RnBleConnectModule.addCharacteristicToService = RnBleConnectModule.addCharacteristicToService;
export const sendNotificationToDevices: typeof RnBleConnectModule.sendNotificationToDevices = RnBleConnectModule.sendNotificationToDevices;
export const start: typeof RnBleConnectModule.start = RnBleConnectModule.start;
export const stop: typeof RnBleConnectModule.stop = RnBleConnectModule.stop;
export const setName: typeof RnBleConnectModule.setName = RnBleConnectModule.setName;
export const getName: typeof RnBleConnectModule.getName = RnBleConnectModule.getName;
export const isAdvertising: typeof RnBleConnectModule.isAdvertising = RnBleConnectModule.isAdvertising;

// 0 means not supported
export const PERMISSIONS = {
    "readable": (Platform.OS === 'ios') ? 1 : 1,
    "readableEncrypted": (Platform.OS === 'ios') ? 4 : 2,
    "readableEncryptedMITM": (Platform.OS === 'ios') ? 0 : 4,
    "writeable": (Platform.OS === 'ios') ? 2 : 16,
    "writeableEncrypted": (Platform.OS === 'ios') ? 8 : 32,
    "writeableEncryptedMITM": (Platform.OS === 'ios') ? 0 : 64,
    "writeableSigned": (Platform.OS === 'ios') ? 0 : 128,
    "writeableSignedMITM": (Platform.OS === 'ios') ? 0 : 256,
  }
  
// 0 means not supported
export const PROPERTIES = {
    "broadcastable": (Platform.OS === 'ios') ? 1 : 1,
    "readable": (Platform.OS === 'ios') ? 2 : 2,
    "writableWithoutResponse": (Platform.OS === 'ios') ? 4 : 4,
    "writable": (Platform.OS === 'ios') ? 8 : 8,
    "supportsNotification": (Platform.OS === 'ios') ? 10 : 16,
    "supportsIndication": (Platform.OS === 'ios') ? 20 : 32,
    "signedWrite": (Platform.OS === 'ios') ? 40 : 64,
    "extendedProperties": (Platform.OS === 'ios') ? 80 : 128,
    "notificationEncrypted": (Platform.OS === 'ios') ? 100 : 0,
    "indicationEncrypted": (Platform.OS === 'ios') ? 200 : 0,
}