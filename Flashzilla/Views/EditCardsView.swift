//
//  EditCardsView.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-06.
//

import SwiftUI

struct EditCardsView: View {
    
    // Access our data store
    @EnvironmentObject var dataStore: Cards
    
    // Whether this sheet is showing or not
    @Environment(\.presentationMode) var presentationMode
    
    // Fields for new card
    @State private var newPrompt = ""
    @State private var newAnswer = ""
    
    private var trimmedPrompt: String {
        return newPrompt.trimmingCharacters(in: .whitespaces)
    }
    
    private var trimmedAnswer: String {
        return newAnswer.trimmingCharacters(in: .whitespaces)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add new card")) {
                    TextField("Prompt", text: $newPrompt)
                    TextField("Answer", text: $newAnswer)
                    Button("Add card", action: addCard)
                        // Don't enable the Add Card button until both a prompt and an answer are provided
                        .disabled(newPrompt.isEmpty || newAnswer.isEmpty)
                }
                
                Section {
                    
                    // Show the list of questions
                    ForEach(0..<dataStore.cards.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(dataStore.cards[index].prompt)
                                .font(.headline)
                            Text(dataStore.cards[index].answer)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: removeCards)
                }
            }
            .navigationBarTitle("Edit Cards")
            .navigationBarItems(trailing: Button("Done", action: dismiss))
            .listStyle(GroupedListStyle())
            .onAppear {
                dataStore.loadCards()
            }
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func addCard() {
        
        // Shouldn't be possible to get here with empty values, and yet...
        let trimmedPrompt = newPrompt.trimmingCharacters(in: .whitespaces)
        let trimmedAnswer = newAnswer.trimmingCharacters(in: .whitespaces)
        
        // Ensure data for both field was entered
        guard trimmedPrompt.isEmpty == false && trimmedAnswer.isEmpty == false else { return }
        
        // Save the new card
        let card = Card(prompt: trimmedPrompt, answer: trimmedAnswer)
        dataStore.addCardToPersistentStorage(card, at: 0)
        
        // Reset fields for next entry
        newAnswer = ""
        newPrompt = ""
        
    }
    
    // Support swipe to delete for a given card
    func removeCards(at offsets: IndexSet) {
        dataStore.removeCardsFromPersistentStorage(at: offsets)
    }
}

struct EditCardsView_Previews: PreviewProvider {
    static var previews: some View {
        EditCardsView()
    }
}
