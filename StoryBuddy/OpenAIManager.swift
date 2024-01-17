//
//  OpenAIManager.swift
//  StoryBuddy
//
//  Created by Aaron Butler on 1/16/24.
//

import Foundation
import OpenAI

final class OpenAIManager {
    static let shared = OpenAIManager()
    
    let openAI = OpenAI(apiToken: "YOUR TOKEN HERE")
    
    static func systemPrompt() -> String {
        "You are designed for creating and illustrating cohesive children's stories, targeting an audience aged 2-10. Your main job is to be a choose your own adventure bot, allowing kids to write their own stories. You ensure a consistent visual style and character appearance throughout each story. You avoid abrupt story interruptions for smooth narrative flow, and segment stories into pages with corresponding illustrations. Give the user options after each page for what to do with the next page. Make it very conversational and more like a choose your own adventure. Add fun emojis throughout and use a playful tone. Let the user decide if they want the story to rhyme or not at the beginning. The entire story should rhyme if they choose yes. Be more whimsical, and always give options to choose from for any question you ask. Dumb down your text a bit so younger kids can understand. Each time a new page of the story is created that is something other than a blank page and is relevant to the plot of the story, add text that describes a photo to generate (with lots of detail of the style of the photo, specifically that it should be in the style of a children's book illustration) to the top of the message in the format: \"^^INSERT THE DESCRIPTION HERE^^\". Make the image description well suited for Dalle Image Generation in a storybook illustration style, including the requested style as well as any necessary information (animal type, location, etc) in the description. Only ask one question at a time, and always list the options with an emoji at the start of each option is relevant to the option rather than an actual number (e.g. \"🪙: Follow the map to find the hidden coin\"). Always have a final option of \"surprise me\" or \"you decide for me\" or something like that. Make the names of places and characters much more fun, descriptive, and alliterative. Create the illustration right away. Don't let users do anything else other than write the story with you. Every question you ask that has options (which all questions must have) should be formatted like: \"[INSERT QUESTION]\n🪙: Follow the map to find the hidden coin\n🪙: Follow the map to find the hidden coin\" The emoji options must always be different from each other (i.e. no two options should have the same emoji) and colons should only be added after emojis for options. There must always be exactly a colon followed by a space after the emojis in the options. Like: \"🪙: [OPTION TEXT]\" Only ask one question at a time."
    }
    
}
final class ChatManager {
    var currentPhotoUrl: String = ""
    
    func startChat(systemPrompt: String? = nil) async throws -> Chat {
        let startingMessage = Chat(role: .system, content: systemPrompt ?? OpenAIManager.systemPrompt())
        let query = ChatQuery(model: .gpt4_1106_preview, messages: [startingMessage])
        do {
            _ = try await OpenAIManager.shared.openAI.chats(query: query)
            
            return startingMessage
        } catch {
            throw error
        }
    }
    
    func sendQuery(text: String, chatHistory: [Chat]) async throws -> Chat {
        var updatedHistory: [Chat] = Array(chatHistory.suffix(5))
        let startingMessage = chatHistory.first ?? Chat(role: .system, content: OpenAIManager.systemPrompt())
        updatedHistory.insert(startingMessage, at: 0)
        
        let query = ChatQuery(model: .gpt4_1106_preview, messages: updatedHistory)
        do {
            let result = try await OpenAIManager.shared.openAI.chats(query: query)
            var content = result.choices.first?.message.content ?? ""
            
            let extractionResult = extractAndRemoveTextAndConsecutiveEmptyLines(in: content)
            content = extractionResult.modifiedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let caption = extractionResult.extracted
            if !caption.isEmpty {
                print(caption.first ?? "")
                let image = try await OpenAIManager.shared.openAI.images(query: .init(prompt: caption.first ?? "",
                                                                                      model: .dall_e_2,
                                                                                      responseFormat: .url,
                                                                                      n: 1,
                                                                                      size: "256x256"))
                currentPhotoUrl = image.data.first?.url ?? ""
            }
            
            return .init(role: .assistant, content: content)
        } catch {
            throw error
        }
    }
    
    func extractAndRemoveTextAndConsecutiveEmptyLines(in text: String) -> (extracted: [String], modifiedText: String) {
        do {
            let extractPattern = "\\^\\^([\\s\\S]*?)\\^\\^"
            let extractRegex = try NSRegularExpression(pattern: extractPattern)
            let nsString = text as NSString
            var extractedTexts = [String]()
            var newString = text
            
            // Extract and remove text surrounded by ^^, including newlines
            let matches = extractRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() { // Use reversed to avoid offset issues while replacing
                if let range = Range(match.range(at: 1), in: text) {
                    let matchedText = text[range]
                    extractedTexts.append(String(matchedText))
                    let fullMatchRange = match.range(at: 0)
                    newString = nsString.replacingCharacters(in: fullMatchRange, with: "")
                }
            }
            
            // Remove consecutive empty lines
            let removeEmptyLinesPattern = "(?:\\n\\s*){2,}"
            let removeEmptyLinesRegex = try NSRegularExpression(pattern: removeEmptyLinesPattern)
            let modifiedString = removeEmptyLinesRegex.stringByReplacingMatches(in: newString, options: [], range: NSRange(location: 0, length: newString.count), withTemplate: "\n")
            
            return (extractedTexts, modifiedString)
        } catch {
            print("Error creating regular expression: \(error)")
            return ([], text)
        }
    }
}

extension Chat: Identifiable, Hashable {
    public var id: String {
        return UUID().uuidString
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}
