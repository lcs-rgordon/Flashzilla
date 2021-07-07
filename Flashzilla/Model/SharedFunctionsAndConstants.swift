//
//  SharedFunctions.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-06.
//

import Foundation

// Return the directory that we can save user data in
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

// Where data is being saved in userDefaults
let settingsRecycleAnswersKey = "FlashzillaRecycleCards"
let settingsHapticsCelebrationKey = "FlashzillaHapticCelebration"
let settingsHapticsIncorrectKey = "FlashzillaHapticIncorrect"
let settingsHapticsCorrectKey = "FlashzillaHapticCorrect"
