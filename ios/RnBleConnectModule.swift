import ExpoModulesCore

public class RnBleConnectModule: Module {
  public func definition() -> ModuleDefinition {
    Name("RnBleConnect")

    Function("hello") {
      return "Hello world! 👋"
    }
  }
}
