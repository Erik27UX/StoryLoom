import SwiftUI

// MARK: - Keyboard dismissal
// Text entry appears on 13 screens, but only two of them let the user close the
// keyboard again — everywhere else it stayed up with no way out, covering the
// Save/Send button. These helpers give every text screen the same three escape
// routes: tap anywhere off the field, swipe the content down, or tap Done.

extension View {
    /// Dismisses the keyboard when the user taps outside a text field.
    ///
    /// Uses a background tap target rather than `.onTapGesture` on the content
    /// itself, so it never swallows taps meant for buttons, links, or rows.
    func dismissKeyboardOnTap() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { KeyboardDismisser.dismiss() }
        )
    }

    /// Adds a "Done" button above the keyboard that dismisses it.
    ///
    /// Only attach this to screens whose keyboard toolbar isn't already used for
    /// something else, to avoid two competing toolbars.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismisser.dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SL.textAccent)
            }
        }
    }

    /// All three dismissal routes at once: tap-away, swipe-down, and Done.
    /// `.scrollDismissesKeyboard(.interactively)` is a no-op on non-scrolling
    /// content, so this is safe to apply broadly.
    func dismissKeyboardAnyGesture() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
    }
}

enum KeyboardDismisser {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
