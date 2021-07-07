//
//  ContentView.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-04.
//

import CoreHaptics
import SpriteKit
import SwiftUI

struct ContentView: View {

    // Access our data store
    @EnvironmentObject var dataStore: Cards
    
    // Access the global app state
    @EnvironmentObject var appState: AppState
    
    // For haptic engine feedback
    @State private var engine: CHHapticEngine?

    // Whether to recycle a card if answered incorrectly
    @AppStorage(settingsRecycleAnswersKey) var recycleIncorrectAnswers: Bool = false
    
    // Stores whether to play haptic celebration at end
    @AppStorage(settingsHapticsCelebrationKey) var playHapticCelebration: Bool = true
        
    /*
     Now, SwiftUI doesn’t have an environment property that tells us when VoiceOver is running, but instead has a general property called \.accessibilityEnabled. This isn’t triggered when things like Differentiate Without Color, Reduce Motion, or Reduce Transparency are enabled, and it’s the closest option SwiftUI gives us to “VoiceOver Running”.
     */
    @Environment(\.accessibilityEnabled) var accessibilityEnabled

    // Whether user has enabled "Differentiate without color"
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    // Whether we are showing the settings screen
    @State private var showingSettingsScreen = false
    
    // Whether we are editing the list of questions
    @State private var showingEditScreen = false
    
    // For countdown timer
    @State private var timeRemaining = 100
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Is a game active?
    @State private var isGameActive = true
    
    // Whether buttons should be disabled
    var buttonsInactive: Bool {
        // User should not be able to press buttons when:
        // 1. Answer is not showing on card

        return appState.isShowingAnswer == false || isGameActive == false
    }
    
    // Scene to present fireworks celebration in
    var scene: SKScene {
        let scene = FireworksScene()
        scene.size = CGSize(width: 300, height: 250)
        scene.backgroundColor = .clear
        scene.view?.allowsTransparency = true
        return scene
    }
    
    var body: some View {
        ZStack {
            
            // Don't have VoiceOver read out anything about this image
            Image(decorative: "background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    print("tapping on background")
                }
            
            // When game is over, play fireworks animation
            if dataStore.noCardsRemain {
                SpriteView(scene: scene)
                    .background(Rectangle()
                                    .fill(Color.clear)
                    )
                    .edgesIgnoringSafeArea(.all)
                    .accessibility(hidden: true)
                    .onAppear {
                        if playHapticCelebration {
                            audioHapticCelebration()
                            hapticCelebration()
                        }
                    }
            }
            
            VStack {
                
                // Show game time remaining
                Text("Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.primary)
                            .colorInvert()
                            .opacity(0.75)
                    )
                
                ZStack {
                    ForEach(0..<dataStore.cardCount, id: \.self) { index in

                        // Show a card
                        //
                        // topOfDeck is true for the final card in the dataStore
                        // (used to determine whether answer should shown)
                        //
                        // removal is the closure that will be run when a card is removed via a swipe
                        CardView(card: dataStore.cards[index],
                                 topOfDeck: index == dataStore.lastCardIndex ? true : false,
                                 removal: { isAnswerCorrect in
                            
                            print("removing card, answer was \(isAnswerCorrect ? "correct" : "incorrect")")

                            // Handle case where cards may need to be recycled on incorrect answer
                            if !isAnswerCorrect {
                                print("answer was incorrect based on swipe left, might be recycling card...")
                                recycleCard()
                            } else {
                                print("answer was correct based on swipe right...")
                            }
                            
                            // Remove card from top of deck
                            withAnimation {
                                print("about to remove card after swipe...")
                                removeCard()
                            }
                            

                        })
                            .stacked(at: index, in: dataStore.cardCount)
                            // Ensure that only the top card can be moved
                            // NOTE: Comment this view modifier out to allow debugging of CardView offsets
                            //       This was key to figuring out the "swipe-left-didn't-remove-card" bug!
                            .allowsHitTesting(index == dataStore.lastCardIndex)
                            // Don't have cards below the top card read by VoiceOver
                            .accessibility(hidden: index < dataStore.lastCardIndex)

                        
                    }
                }
                // Allow responses to user touch only if there is time remaining
                .allowsHitTesting(timeRemaining > 0)
                
                // Allow a new game to begin
                if dataStore.noCardsRemain {
                    Button("Start Again", action: startNewGame)
                        .padding()
                        .foregroundColor(Color.primary)
                        .background(Color.primary.colorInvert())
                        .clipShape(Capsule())
                }
                
            }
            
            // Access settings screen
            VStack {
                HStack {
                    Button(action: {
                        showingSettingsScreen = true
                    }) {
                        Image(systemName: "gear")
                            .padding()
                            .foregroundColor(Color.primary)
                            .colorInvert()
                            .background(Color.primary.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Spacer()

                }

                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            
            // Allow questions to be added
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        showingEditScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                            .padding()
                            .foregroundColor(Color.primary)
                            .colorInvert()
                            .background(Color.primary.opacity(0.7))
                            .clipShape(Circle())
                    }
                }

                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            
            // Ensure the buttons show up if differentiating without color or VoiceOver is on
            if differentiateWithoutColor || accessibilityEnabled {
                VStack {
                    
                    // Push the buttons down to bottom of screen
                    Spacer()

                    HStack {
                        
                        // Left side, answer is wrong
                        Button(action: {

                            // Handle case where cards may need to be recycled on incorrect answer
                            print("answer was incorrect based on 'wrong' button tap, might be recycling card...")
                            recycleCard()
                            
                            // Remove card from top of deck
                            withAnimation {
                                print("responding to 'incorrect' button tap, about to remove card...")
                                removeCard()
                            }

                        },
                               label: {
                            Image(systemName: "xmark.circle")
                                .font(.largeTitle)
                                .foregroundColor(Color.primary)
                                .colorInvert()
                                .padding()
                                // Dim the button somewhat when inactive
                                .background(buttonsInactive ? Color.primary.opacity(0.4) : Color.primary.opacity(0.7))
                                .clipShape(Circle())
                        })
                        .accessibility(label: Text("Wrong"))
                        .accessibility(hint: Text("Mark your answer as being incorrect."))
                        // Don't allow button to respond
                        .disabled(buttonsInactive)

                        // Separate views, one button at left, one at right
                        Spacer()
                        
                        // Right side, answer is correct
                        Button(action: {

                            // Remove card from top of deck
                            withAnimation {
                                print("responding to 'correct' button tap, about to remove card...")
                                removeCard()
                            }

                        },
                               label: {
                            Image(systemName: "checkmark.circle")
                                .font(.largeTitle)
                                .foregroundColor(Color.primary)
                                .colorInvert()
                                .padding()
                                // Dim the button somewhat when it is disabled
                                .background(buttonsInactive ? Color.primary.opacity(0.4) : Color.primary.opacity(0.7))
                                .clipShape(Circle())
                        })
                        .accessibility(label: Text("Correct"))
                        .accessibility(hint: Text("Mark your answer as being correct."))
                        // Don't allow button to respond
                        .disabled(buttonsInactive)

                    }
                    .padding()
                }
            }
            
        }
        // Make the timer count down
        .onReceive(timer) { time in
            // Exit this closure if a game is not active
            guard isGameActive else { return }
            // If we're here, the game is active/on, so reduce the time
            if timeRemaining > 0 {
                
                // Reduce the time
                timeRemaining -= 1
                
                // If there is just one card left, prepare the haptic engine
                prepareHaptics()
                
            } else if timeRemaining == 0 {
                // When time is up, the game is no longer active
                isGameActive = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Pause the game when the app is backgrounded
            isGameActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            
            print("Entering foreground, are we recycling incorrect answers? \(recycleIncorrectAnswers)")
            
            // Only resume action in the app if there are cards left and time remains
            if !dataStore.noCardsRemain && timeRemaining > 0 {
                isGameActive = true
            }
        }
        .sheet(isPresented: $showingEditScreen, onDismiss: startNewGame) {
            EditCardsView()
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingSettingsScreen) {
            SettingsView()
        }
        .onAppear {
            print("On appear, are we recycling incorrect answers?  \(recycleIncorrectAnswers)")
            startNewGame()
        }
    }

    func recycleCard() {

        // Depending on app setting, make a copy of the card and put at back of deck
        if recycleIncorrectAnswers {
            
            dataStore.recycleCard()
            
        }

    }
    
    func removeCard() {

        // Remove the card from the top of the deck
        dataStore.removeCard()

        // Don't show answer any more
        appState.isShowingAnswer = false
        
        // End the game if there are no more cards left
        if dataStore.noCardsRemain {
            isGameActive = false
        }
        
    }
    
    // Allow a new game to begin
    func startNewGame() {
        timeRemaining = 100
        isGameActive = true
        dataStore.loadCards()
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            self.engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    // See: https://www.donnywals.com/adding-haptics-to-your-app/
    // ... for details
    func audioHapticCelebration() {
        
        let events = [
        CHHapticEvent(eventType: .audioContinuous, parameters: [
          CHHapticEventParameter(parameterID: .audioPitch, value: 0.3),
          CHHapticEventParameter(parameterID: .audioVolume, value: 0.7),
          CHHapticEventParameter(parameterID: .decayTime, value: 0.05),
            CHHapticEventParameter(parameterID: .sustained, value: 0.5)
        ], relativeTime: 0)
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // something went wrong
        }
        
    }
    
    // See: https://www.donnywals.com/adding-haptics-to-your-app/
    // ... for details
    func hapticCelebration() {
        
        let events = [
          CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
          ], relativeTime: 0.1, duration: 5)
        ]

        let dynamicParameters = [
          CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                 controlPoints: [.init(relativeTime: 0, value: 0),
                                                 .init(relativeTime: 1, value: 1),
                                                 .init(relativeTime: 2, value: 0.5),
                                                 .init(relativeTime: 3, value: 1)],
                                 relativeTime: 0)]
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: dynamicParameters)
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // something went wrong
        }
    }
        
}

/*
 In this case we’re going to create a new stacked() modifier that takes a position in an array along with the total size of the array, and offsets a view by some amount based on those values. This will allow us to create an attractive card stack where each card is a little further down the screen than the ones before it.
 */
extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: offset * 2, height: offset * 5))
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


