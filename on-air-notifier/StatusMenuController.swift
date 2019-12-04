import Cocoa

class StatusMenuController: NSObject, PreferencesWindowDelegate {
  @IBOutlet var statusMenu: NSMenu!
  @IBOutlet var onAirMenuItem: NSMenuItem!
  @IBOutlet var onAirView: OnAirView!
  
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var preferencesWindow: PreferencesWindow!
  private var cameraWatcher: CameraWatcher!
  
  override func awakeFromNib() {
    let icon = NSImage(named: "statusIcon")
    icon?.isTemplate = true
    statusItem.button?.image = icon
    statusItem.menu = statusMenu
    
    onAirMenuItem.view = onAirView
    
    cameraWatcher = CameraWatcher()
    cameraWatcher.setupCameraIsRunnningListeners()
    cameraWatcher.addOnAirListener(listener: onOnAirUpdate)
    
    preferencesWindow = PreferencesWindow()
    preferencesWindow.delegate = self
  }
  
  public func preferencesDidUpdate() {
    notifyHttpHook(onAir: cameraWatcher.onAirState)
  }
  
  private func onOnAirUpdate(onAir: Bool) {
    onAirView.updateOnAir(onAir: onAir)
    notifyHttpHook(onAir: onAir)
  }
  
  private func notifyHttpHook(onAir: Bool) {
    let baseUrl = UserDefaults.standard.string(forKey: "url") ?? ""
    if baseUrl != "" {
      let url = URL(string: "\(baseUrl)?onAir=\(onAir)")!
      let session = URLSession.shared
      let task = session.dataTask(with: url) // We are not interested in the response
      task.resume()
    }
  }
  
  @IBAction func preferencesClicked(sender: NSMenuItem) {
    preferencesWindow.sendToFrontAndShow()
  }
  
  @IBAction func quitClicked(sender: NSMenuItem) {
    NSApplication.shared.terminate(self)
  }
}
