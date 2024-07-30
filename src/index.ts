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
  hello,
} = RnBleConnectModule;

export {
  hello,
  addService,
  addCharacteristicToService,
  sendNotificationToDevices,
  start,
  stop,
  setName,
  getName,
  isAdvertising,
};
