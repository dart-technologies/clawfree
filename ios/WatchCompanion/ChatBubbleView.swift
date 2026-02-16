import SwiftUI

/// A single chat bubble (user = right/gray, AI = left/blue).
struct ChatBubble: View {
    let text: String
    let isUser: Bool

    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal = Color(red: 0.0, green: 0.75, blue: 0.65)

    var body: some View {
        HStack {
            if isUser { Spacer() }

            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUser
                              ? Color.gray.opacity(0.3)
                              : teal.opacity(0.3))
                )
                .frame(maxWidth: 140, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
    }
}

/// A scrollable chat history for Watch.
struct ChatHistoryView: View {
    let messages: [(text: String, isUser: Bool)]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { idx, msg in
                        ChatBubble(text: msg.text, isUser: msg.isUser)
                            .id(idx)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: messages.count) { _ in
                withAnimation {
                    proxy.scrollTo(messages.count - 1, anchor: .bottom)
                }
            }
        }
    }
}
