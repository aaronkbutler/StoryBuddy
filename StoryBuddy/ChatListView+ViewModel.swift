//
//  ChatListView+ViewModel.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/16/24.
//

import SwiftUI
import OpenAI

extension ChatListView {
    @MainActor final class ViewModel: ObservableObject {
        @AppStorage("chats") var chats: [[Chat]] = []
        
        func saveChat(chatContents: [Chat]) {
            chats.append(chatContents)
        }
    }
}

extension Array: Identifiable {
    public var id: String {
        UUID().uuidString
    }
    
    
}
