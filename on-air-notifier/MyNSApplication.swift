import AppKit
import Foundation

@objc(MyNSApplication)
class MyNSApplication: NSApplication {
  private let commandKey = NSEvent.ModifierFlags.command.rawValue
  private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue

  // Taken from: https://stackoverflow.com/a/3176930 and modified.
  override func sendEvent(_ event: NSEvent) {
    if event.type == NSEvent.EventType.keyDown {
      if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
        switch event.charactersIgnoringModifiers! {
        case "x":
          if self.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return }
        case "c":
          if self.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return }
        case "v":
          if self.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return }
        case "z":
          if self.sendAction(Selector(("undo:")), to: nil, from: self) { return }
        case "a":
          if self.sendAction(#selector(NSStandardKeyBindingResponding.selectAll(_:)), to: nil, from: self) { return }
        default:
          break
        }
      }
      else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
        if event.charactersIgnoringModifiers == "Z" {
          if self.sendAction(Selector(("redo:")), to: nil, from: self) { return }
        }
      }
    }
    super.sendEvent(event)
  }
}
