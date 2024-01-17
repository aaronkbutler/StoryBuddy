//
//  StoryBuddyApp.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/12/24.
//

import SwiftUI

@main
struct StoryBuddyApp: App {
    var body: some Scene {
        WindowGroup {
//            ChatListView()
            ChatView(viewModel: .init(index: 0, chatHistory: []))
        }
    }
}
