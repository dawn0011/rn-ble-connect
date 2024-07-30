import RnBleConnectModule from "./RnBleConnectModule";

const {
  addService,
  addCharacteristicToService,
  sendNotificationToDevices,
  start,
  stop,
  setName,
  getName,
  isAdvertising,
} = RnBleConnectModule;

export {
  addService,
  addCharacteristicToService,
  sendNotificationToDevices,
  start,
  stop,
  setName,
  getName,
  isAdvertising,
};
