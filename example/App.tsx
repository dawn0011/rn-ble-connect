import { StyleSheet, Text, View } from "react-native";
import * as RnBleConnect from "rn-ble-connect";

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{RnBleConnect.hello()}</Text>
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
