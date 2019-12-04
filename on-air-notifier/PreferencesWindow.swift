import Cocoa

protocol PreferencesWindowDelegate {
  func preferencesDidUpdate() -> Void
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
  @IBOutlet var urlTextField: NSTextField!

  var delegate: PreferencesWindowDelegate?

  override var windowNibName: String! {
    return "PreferencesWindow"
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    self.urlTextField.stringValue = UserDefaults.standard.string(forKey: "url") ?? ""

    self.window?.center()
    self.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  public func windowWillClose(_ notification: Notification) {
    let defaults = UserDefaults.standard
    defaults.setValue(self.urlTextField.stringValue, forKey: "url")
    self.delegate?.preferencesDidUpdate()
  }
}
