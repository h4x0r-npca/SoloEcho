import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private enum DesktopWindowSize {
    static let contentSize = NSSize(width: 420, height: 820)
    static let minimumContentSize = NSSize(width: 360, height: 640)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.contentMinSize = DesktopWindowSize.minimumContentSize
    self.setContentSize(DesktopWindowSize.contentSize)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
