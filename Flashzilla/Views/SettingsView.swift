//
//  SettingsView.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-06.
//

import SwiftUI

struct SettingsView: View {
    // Whether this sheet is showing or not
    @Environment(\.presentationMode) var presentationMode
    
    // Stores whether the user wants to recycle answers when they do not guess correctly
    @AppStorage(settingsRecycleAnswersKey) var recycleIncorrectAnswers: Bool = false
    
    // Stores whether to play haptic celebration at end
    @AppStorage(settingsHapticsCelebrationKey) var playHapticCelebration: Bool = true

    // Stores whether to play haptic feedback during game
    @AppStorage(settingsHapticsCorrectKey) var playHapticOnCorrectAnswer: Bool = true
    @AppStorage(settingsHapticsIncorrectKey) var playHapticOnIncorrectAnswer: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Card re-use")) {
                    Toggle("Recycle cards when answer incorrect?", isOn: $recycleIncorrectAnswers)
                }
                Section(header: Text("Haptics")) {
                    Toggle("Celebration when game complete?", isOn: $playHapticCelebration)
                    Toggle("Feedback on correct answer?", isOn: $playHapticOnCorrectAnswer)
                    Toggle("Feedback on incorrect answer?", isOn: $playHapticOnIncorrectAnswer)
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button("Done", action: dismiss))
            .listStyle(GroupedListStyle())
        
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
