import Cocoa

class OnAirView: NSView {
  @IBOutlet var onAirImage: NSImageView!
  @IBOutlet var onAirLabel: NSTextField!

  let imageOnAir = NSImage(named: "onAir")
  let imageOffAir = NSImage(named: "offAir")
  
  public func updateOnAir(onAir: Bool) {
    DispatchQueue.main.async {
      if onAir {
        self.onAirImage.image = self.imageOnAir
        self.onAirLabel.stringValue = "On Air!"
      } else {
        self.onAirImage.image = self.imageOffAir
        self.onAirLabel.stringValue = "Off Air."
      }
      self.onAirImage.needsLayout = true
      self.onAirImage.needsDisplay = true
      self.onAirImage.layout()
    }
  }
}
