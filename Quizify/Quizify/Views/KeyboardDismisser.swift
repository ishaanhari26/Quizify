import UIKit
import SwiftUI

class KeyboardDismisser: NSObject {
    static let shared = KeyboardDismisser()
    private var tapGesture: UITapGestureRecognizer?
    
    private override init() {
        super.init()
    }
    
    func setupKeyboardDismissal() {
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        addTapGesture()
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        removeTapGesture()
    }
    
    private func addTapGesture() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        // Remove existing gesture if any
        removeTapGesture()
        
        // Create new tap gesture
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        
        // Store reference to the gesture
        self.tapGesture = gesture
        
        // Add gesture to the window
        window.addGestureRecognizer(gesture)
    }
    
    private func removeTapGesture() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let gesture = self.tapGesture else { return }
        
        window.removeGestureRecognizer(gesture)
        self.tapGesture = nil
    }
    
    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// UIGestureRecognizerDelegate methods
extension KeyboardDismisser: UIGestureRecognizerDelegate {
    // This method ensures the tap gesture doesn't interfere with other gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // This method makes sure we don't dismiss the keyboard when tapping on text fields
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't trigger if the touch is on a UIControl (like a text field, button, etc.)
        if let touchView = touch.view, touchView is UIControl {
            return false
        }
        return true
    }
}
