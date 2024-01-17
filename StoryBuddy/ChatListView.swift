//
//  ChatListView.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/16/24.
//

import SwiftUI

struct ChatListView: View {
    @StateObject var viewModel = ChatListView.ViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: ChatView(viewModel: .init(index: viewModel.chats.firstIndex(of: chat) ?? 0, chatHistory: chat))) {
                        Text(chat.first?.content?.prefix(10) ?? "New chat")
                    }
                }
                .onDelete { indexSet in
                    viewModel.chats.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: ChatView(viewModel: .init(index: viewModel.chats.count, chatHistory: []))) {
                        Label("New Chat", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ChatListView()
}
