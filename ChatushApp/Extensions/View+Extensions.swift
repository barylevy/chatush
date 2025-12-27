import SwiftUI

extension View {
    /// Dismisses the keyboard when the user scrolls or drags
    func dismissKeyboardOnScroll() -> some View {
        self.simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
    
    /// Adds a clear button that appears when the textfield has text and is focused
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButton(text: text))
    }
}

struct ClearButton: ViewModifier {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        HStack {
            content
                .focused($isFocused)
            
            if !text.isEmpty && isFocused {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
