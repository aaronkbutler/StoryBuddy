//
//  ChatView.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/15/24.
//

import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatView.ViewModel
    
    var body: some View {
        VStack {
            if !viewModel.currentPhotoUrl.isEmpty {
                AsyncImage(url: URL(string: viewModel.currentPhotoUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                    }
                }
            }
            ScrollViewReader { scrollView in
                VStack {
                    ScrollView(.vertical) {
                        VStack {
                            ForEach(viewModel.chatHistory) { chatMessage in
                                HStack {
                                    if chatMessage.role == .user {
                                        Spacer()
                                    }
                                    if chatMessage.role != .system {
                                        Text(chatMessage.content ?? "")
                                            .padding()
                                            .background(chatMessage.role == .user ? .blue : .gray)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                    }
                                }
                            }
                        }
                        .id("ChatScrollView")
                    }
                    .onAppear {
                        withAnimation {
                            scrollView.scrollTo("ChatScrollView", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.chatHistory, { oldValue, newValue in
                        withAnimation {
                            scrollView.scrollTo("ChatScrollView", anchor: .bottom)
                        }
                    })
                    .listStyle(.plain)
                    HStack {
                        ForEach(viewModel.buttons, id: \.self) { button in
                            Button {
                                Task {
                                    do {
                                        try await viewModel.sendQuery(text: button)
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                }
                            } label: {
                                Text(button)
                                    .font(.title)
                            }
                            .disabled(viewModel.isLoading)
                            .padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Story Buddy")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.chatHistory.isEmpty {
                do {
                    try await viewModel.startChat()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ChatView(viewModel: .init(index: 0, chatHistory: []))
}
