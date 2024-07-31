import RnBleConnectModule from "./RnBleConnectModule";

export const addService: typeof RnBleConnectModule.addService = RnBleConnectModule.addService;
export const addCharacteristicToService: typeof RnBleConnectModule.addCharacteristicToService = RnBleConnectModule.addCharacteristicToService;
export const sendNotificationToDevices: typeof RnBleConnectModule.sendNotificationToDevices = RnBleConnectModule.sendNotificationToDevices;
export const start: typeof RnBleConnectModule.start = RnBleConnectModule.start;
export const stop: typeof RnBleConnectModule.stop = RnBleConnectModule.stop;
export const setName: typeof RnBleConnectModule.setName = RnBleConnectModule.setName;
export const getName: typeof RnBleConnectModule.getName = RnBleConnectModule.getName;
export const isAdvertising: typeof RnBleConnectModule.isAdvertising = RnBleConnectModule.isAdvertising;


// const {
//   addService,
//   addCharacteristicToService,
//   sendNotificationToDevices,
//   start,
//   stop,
//   setName,
//   getName,
//   isAdvertising,
// } = RnBleConnectModule;

// export {
//   addService,
//   addCharacteristicToService,
//   sendNotificationToDevices,
//   start,
//   stop,
//   setName,
//   getName,
//   isAdvertising,
// };
