//
//  Card.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-05.
//

import Foundation

struct Card: Codable, Identifiable {
    
    enum CodingKeys: CodingKey {
        case prompt, answer
    }
    
    let id = UUID()
    let prompt: String
    let answer: String
    
    static var example: Card {
        Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
    }
    static var example2: Card {
        Card(prompt: "Who was the first captain of the original Enterprise, NCC 1701?", answer: "Robert April")
    }
    static var example3: Card {
        Card(prompt: "Who played Starbuck in the Battlestar Galactica remake?", answer: "Katee Sackhoff")
    }
    static var example4: Card {
        Card(prompt: "Who played Wesley Crusher on Star Trek: The Next Generation?", answer: "Wil Wheaton")
    }

}

class Cards: ObservableObject {
    
    static let cardsKey = "Cards"
    
    // Prevent external writes to the cards array
    @Published private(set) var cards: [Card] = []
    
    var lastCardIndex: Int {
        return cards.count - 1
    }
    
    var cardCount: Int {
        return cards.count
    }
    
    var noCardsRemain: Bool {
        return cards.isEmpty
    }
    
    init() {
        
    }
    
    // Add a card to the list of cards, saved to Documents directory
    func addCardToPersistentStorage(_ card: Card, at index: Int) {
        
        cards.insert(card, at: index)
        saveCards()
        
    }
    
    // Remove card(s) from the list of cards, saved to Documents directory
    func removeCardsFromPersistentStorage(at offsets: IndexSet) {
        
        cards.remove(atOffsets: offsets)
        saveCards()

    }
    
    // Add a card during game play
    func addCard(_ card: Card, at index: Int) {
        
        cards.insert(card, at: index)
        
    }
    
    // Recycle a card when it was answered incorrectly
    func recycleCard() {
        
        print("recycling card...")
        print("cards count is \(cards.count)")

        // Copy to bottom of deck
        cards.insert(cards.last!, at: 0)
        
        print("cards count is \(cards.count)")
        
    }
    
    // Remove a card from top of deck during game play
    func removeCard() {
        
        print("removing card...")
        print("removing last card and cards.count is: \(cards.count)")
                
        cards.remove(at: cards.count - 1)
        
        print("cards.count is now \(cards.count)")
        
        // What are the cards?
        for (index, card) in cards.enumerated() {
            print("\(index): \(card.prompt)")
        }

    }
        
    // Save list of cards to persistent storage
    private func saveCards() {
        
        // Get a URL that points to the saved JSON data containing our cards
        let filename = getDocumentsDirectory().appendingPathComponent(Cards.cardsKey)

        do {
            
            // Create an encoder
            let encoder = JSONEncoder()
            #if DEBUG
            encoder.outputFormatting = .prettyPrinted
            #endif
            
            // Encode the list of prospects we've collected
            let data = try encoder.encode(self.cards)
            
            // Actually write the JSON file to the documents directory
            try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
            
            #if DEBUG
            print("Saved data to documents directory successfully.")
            #endif
            
        } catch {
            
            #if DEBUG
            print(error.localizedDescription)
            print("Unable to write list of cards to documents directory.")
            #endif
        }
        
        
    }
    
    // Load the list of cards from persistent storage
    func loadCards() {
        
        // Get a URL that points to the saved JSON data containing our cards
        let filename = getDocumentsDirectory().appendingPathComponent(Cards.cardsKey)
        
        // Attempt to load from the JSON in the stored file
        do {
            
            // Load the raw data
            let data = try Data(contentsOf: filename)
            
            #if DEBUG
            print("Got data from file, contents are:")
            print(String(data: data, encoding: .utf8)!)
            #endif
            
            // Decode the data into Swift native data structures
            self.cards = try JSONDecoder().decode([Card].self, from: data)
            
        } catch {
            
            #if DEBUG
            print(error.localizedDescription)
            print("Could not load data from file, initializing with example data.")
            #endif
            
            self.cards = [Card.example2, Card.example, Card.example4, Card.example3]

        }
        
    }
    
}
