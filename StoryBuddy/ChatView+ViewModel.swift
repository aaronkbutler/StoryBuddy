//
//  ChatView+ViewModel.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/16/24.
//

import SwiftUI
import OpenAI

extension ChatView {
    @MainActor final class ViewModel: ObservableObject {
        @AppStorage("chats") var chats: [[Chat]] = []
        
        let index: Int
        
        @Published var currentPhotoUrl: String = ""
        
        @Published var isLoading = true
        
        @Published var buttons: [String] = ["Let's write a story!"]
        
        @Published var chatHistory: [Chat] {
            didSet {
                if index < chats.count {
                    chats[index] = chatHistory
                } else {
                    chats.append(chatHistory)
                }
            }
        }
        
        let chatManager = ChatManager()
        
        init(index: Int, chatHistory: [Chat]) {
            self.index = index
            self.chatHistory = chatHistory
        }
        
        func startChat() async throws {
            isLoading = true
            do {
                chatHistory = [try await chatManager.startChat()]
                isLoading = false
            } catch {
                print(error.localizedDescription)
                isLoading = false
            }
        }
        
        func sendQuery(text: String) async throws {
            isLoading = true
            
            chatHistory.append(.init(role: .user, content: text))
            
            do {
                let chatResponse = try await chatManager.sendQuery(text: text, chatHistory: chatHistory)
                chatHistory.append(chatResponse)
                
                buttons = scanResponse(chatResponse.content)
                
                if !chatManager.currentPhotoUrl.isEmpty {
                    currentPhotoUrl = chatManager.currentPhotoUrl
                    chatManager.currentPhotoUrl = ""
                }
                
                isLoading = false
            } catch {
                print(error.localizedDescription)
                isLoading = false
            }
        }
        
        func scanResponse(_ responseText: String?) -> [String] {
            guard let responseText else { return ["Try Again"] }
            
            print(responseText)
            
            let emojis = findEmojisFollowedByColonAndSpace(in: responseText)
            
            return emojis
        }
        
        func findEmojisFollowedByColonAndSpace(in text: String) -> [String] {
            do {
                let regex = try NSRegularExpression(pattern: "((?:\\p{Emoji}\\p{Emoji_Modifier_Base}?\\p{Emoji_Modifier}?|\\p{Emoji_Presentation}|\\p{Emoji}\\uFE0F|\\p{Emoji_Component})\\p{Extended_Pictographic}?):\\s", options: [])
                
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                var emojis = [String]()
                for match in matches {
                    if let range = Range(match.range(at: 1), in: text) {
                        let matchedText = text[range]
                        emojis.append(String(matchedText))
                    }
                }
                return emojis
            } catch {
                print("Error creating regular expression: \(error)")
                return []
            }
        }
    }
}


