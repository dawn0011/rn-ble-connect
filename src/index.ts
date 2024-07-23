import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to RnBleConnect.web.ts
// and on native platforms to RnBleConnect.ts
import RnBleConnectModule from './RnBleConnectModule';
import RnBleConnectView from './RnBleConnectView';
import { ChangeEventPayload, RnBleConnectViewProps } from './RnBleConnect.types';

// Get the native constant value.
export const PI = RnBleConnectModule.PI;

export function hello(): string {
  return RnBleConnectModule.hello();
}

export async function setValueAsync(value: string) {
  return await RnBleConnectModule.setValueAsync(value);
}

const emitter = new EventEmitter(RnBleConnectModule ?? NativeModulesProxy.RnBleConnect);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { RnBleConnectView, RnBleConnectViewProps, ChangeEventPayload };
