import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { RnBleConnectViewProps } from './RnBleConnect.types';

const NativeView: React.ComponentType<RnBleConnectViewProps> =
  requireNativeViewManager('RnBleConnect');

export default function RnBleConnectView(props: RnBleConnectViewProps) {
  return <NativeView {...props} />;
}
