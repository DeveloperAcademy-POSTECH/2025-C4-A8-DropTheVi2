import RealityKit

// Ensure you register this component in your app’s delegate using:
// DrawerStateComponent.registerComponent()
public struct DrawerStateComponent: Component, Codable {
    // This is an example of adding a variable to the component.
    var isOpen: Bool = false
  

  public init(isOpen: Bool = false) {
    self.isOpen = isOpen
    }
}
