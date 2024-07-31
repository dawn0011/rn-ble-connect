declare module 'RnBleConnect' {
  export function addService(UUID: string, primary: boolean): void;
  
  export function addCharacteristicToService(
    ServiceUUID: string,
    UUID: string,
    permissions: number,
    properties: number,
    characteristicData?: string
  ): void;
  
  export function sendNotificationToDevices(
    ServiceUUID: string,
    CharacteristicUUID: string,
    data: number[]
  ): void;
  
  export function start(): Promise<boolean>;
  
  export function stop(): void;
  
  export function setName(name: string): void;
  
  export function getName(): string;
  
  export function isAdvertising(): Promise<boolean>;
}