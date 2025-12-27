import SwiftUI
import Combine

extension View {
    /// Dismisses the keyboard when the user scrolls down
    func dismissKeyboardOnScroll() -> some View {
        self.simultaneousGesture(
            DragGesture().onChanged { value in
                // Only dismiss keyboard when scrolling down (positive translation.height)
                if value.translation.height > 0 {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        )
    }
    
    /// Adds a clear button that appears when the textfield has text and is focused
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButton(text: text))
    }
    
    /// Scrolls to the bottom (last visible item) when the keyboard appears
    /// - Parameters:
    ///   - proxy: ScrollViewReader proxy for scrolling
    ///   - bottomId: The ID of the bottom-most element to scroll to
    func scrollToBottomOnKeyboard(
        proxy: ScrollViewProxy,
        bottomId: any Hashable
    ) -> some View {
        modifier(KeyboardScrollModifier(proxy: proxy, bottomId: bottomId))
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

struct KeyboardScrollModifier: ViewModifier {
    let proxy: ScrollViewProxy
    let bottomId: any Hashable
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onChange(of: keyboardHeight) { oldHeight, newHeight in
                if newHeight > oldHeight {
                    // Keyboard is appearing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(bottomId, anchor: .bottom)
                        }
                    }
                }
            }
            .onReceive(Publishers.keyboardHeight) { height in
                keyboardHeight = height
            }
    }
}
