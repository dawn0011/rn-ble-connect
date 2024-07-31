import { requireNativeModule } from 'expo-modules-core';

interface RnBleConnectInterface {
  addService(UUID: string, primary: boolean): void;
  addCharacteristicToService(
    ServiceUUID: string,
    UUID: string,
    permissions: number,
    properties: number,
    characteristicData?: string
  ): void;
  sendNotificationToDevices(
    ServiceUUID: string,
    CharacteristicUUID: string,
    data: number[]
  ): void;
  start(): Promise<boolean>;
  stop(): void;
  setName(name: string): void;
  getName(): string;
  isAdvertising(): Promise<boolean>;
}

let RnBleConnectModule: RnBleConnectInterface;

try {
  RnBleConnectModule = requireNativeModule('RnBleConnect');
} catch (error) {
  console.error("Failed to load RnBleConnect native module:", error);
  throw new Error("RnBleConnect module is not available");
}

export default RnBleConnectModule;