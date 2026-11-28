import Carbon
import Foundation

// Select the same built-in sources a user can enable in System Settings.
func sourceID(_ source: TISInputSource) -> String {
    let value = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)!
    return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
}
if CommandLine.arguments[1] == "prepare" {
    let sources = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    // Input modes can only be enabled after their parent input method.
    let parent = "com.apple.inputmethod.SCIM"
    for id in ["com.apple.keylayout.ABC", parent, "com.apple.inputmethod.SCIM.ITABC"] {
        guard let source = sources.first(where: { sourceID($0) == id }) else {
            fatalError("Built-in input source unavailable: \(id)")
        }
        let enabled = TISEnableInputSource(source)
        guard enabled == noErr else {
            fatalError("Cannot enable input source: \(id), OSStatus \(enabled)")
        }
        if id != parent {
            let selected = TISSelectInputSource(source)
            guard selected == noErr else {
                fatalError("Cannot select input source: \(id), OSStatus \(selected)")
            }
        }
    }
    let deadline = Date().addingTimeInterval(10)
    while sourceID(TISCopyCurrentKeyboardInputSource().takeRetainedValue()) != "com.apple.inputmethod.SCIM.ITABC" {
        guard Date() < deadline else {
            fatalError("Chinese input source did not become active in this desktop session")
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
}
print(sourceID(TISCopyCurrentKeyboardInputSource().takeRetainedValue()))
