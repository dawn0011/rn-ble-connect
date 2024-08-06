import { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import * as RnBleConnect from "rn-ble-connect";


const BLE_DATA_TRANSMIT_SERVICE = 'bea99000-0000-0000-0000-000000000000';
const CHARACTERISTIC_1 = 'bea99000-0000-0000-0000-000000000000';
const CHARACTERISTIC_2 = 'bea99001-0000-0000-0000-000000000000';

export default function App() {
  const [status, setStatus] = useState('App Start')

  useEffect(() => {
    RnBleConnect.addService(BLE_DATA_TRANSMIT_SERVICE, true);

    RnBleConnect.addCharacteristicToService(
      BLE_DATA_TRANSMIT_SERVICE,
      CHARACTERISTIC_1,
      1,
      2,
      "123"
    );

    RnBleConnect.addCharacteristicToService(
      BLE_DATA_TRANSMIT_SERVICE,
      CHARACTERISTIC_2,
      1,
      2,
      "321"
    );

    RnBleConnect.start().then(() => { console.log("--STARTED--") })
  
  }, [])
  

  return (
    <View style={styles.container}>
      <Text>{RnBleConnect.getName()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
});
