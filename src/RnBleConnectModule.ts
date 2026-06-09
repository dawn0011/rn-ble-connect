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
  /**
   * Start BLE advertising.
   * @param durationMs If > 0, a native Android timer stops advertising automatically after this
   *   many milliseconds (unaffected by JS engine throttling). Pass 0 to advertise indefinitely.
   */
  start(durationMs: number): Promise<boolean>;
  stop(): void;
  setName(name: string): void;
  getName(): string;
  isAdvertising(): boolean;
}

let RnBleConnectModule: RnBleConnectInterface;

try {
  RnBleConnectModule = requireNativeModule('RnBleConnect');
} catch (error) {
  console.error("Failed to load RnBleConnect native module:", error);
  throw new Error("RnBleConnect module is not available");
}

export default RnBleConnectModule;