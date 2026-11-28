import Carbon
import Foundation

// Select the same built-in sources a user can enable in System Settings.
func sourceID(_ source: TISInputSource) -> String {
    let value = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)!
    return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
}
if CommandLine.arguments[1] == "prepare" {
    let sources = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    for id in ["com.apple.keylayout.ABC", "com.apple.inputmethod.SCIM.ITABC"] {
        guard let source = sources.first(where: { sourceID($0) == id }) else {
            fatalError("Built-in input source unavailable: \(id)")
        }
        guard TISEnableInputSource(source) == noErr, TISSelectInputSource(source) == noErr else {
            fatalError("Cannot enable/select input source: \(id)")
        }
    }
}
print(sourceID(TISCopyCurrentKeyboardInputSource().takeRetainedValue()))
