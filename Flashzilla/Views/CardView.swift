//
//  CardView.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-05.
//

import SwiftUI

struct CardView: View {
    
    // Access the global app state
    @EnvironmentObject var appState: AppState
    
    // Stores whether to play haptic feedback during game
    @AppStorage(settingsHapticsCorrectKey) var playHapticOnCorrectAnswer: Bool = true
    @AppStorage(settingsHapticsIncorrectKey) var playHapticOnIncorrectAnswer: Bool = false

    // For haptic engine feedback
    @State private var feedback = UINotificationFeedbackGenerator()
    
    /*
     Now, SwiftUI doesn’t have an environment property that tells us when VoiceOver is running, but instead has a general property called \.accessibilityEnabled. This isn’t triggered when things like Differentiate Without Color, Reduce Motion, or Reduce Transparency are enabled, and it’s the closest option SwiftUI gives us to “VoiceOver Running”.
     */
    @Environment(\.accessibilityEnabled) var accessibilityEnabled
    
    // Whether user has enabled "Differentiate without color"
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    // The card to show
    var card: Card
    
    // Whether this card is at the top of the deck
    var topOfDeck: Bool
    
    // Accepts a closure to handle removal of this card when dragged off the stack
    // Parameter: whether the user guessed correctly on this card, true if the guess was correct
    var removal: ((_: Bool) -> Void)? = nil
    
    // Track how far the user has dragged this card
    @State private var offset = CGSize.zero
    
    // Stores whether the user wants to recycle answers when they do not guess correctly
    @AppStorage(settingsRecycleAnswersKey) var recycleIncorrectAnswers: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    // Disable red/green change if user cannot distinguish these colours
                    differentiateWithoutColor
                        ? Color.primary
                        : Color.primary
                            // Show the red or green as soon as we start to drag
                            .opacity(1 - Double(abs(offset.width / 50)))
                )
                .colorInvert()
                .background(
                    // Disable red/green change if user cannot distinguish these colours
                    differentiateWithoutColor
                        ? nil
                        : RoundedRectangle(cornerRadius: 25, style: .continuous)
                            // Swipe right, green... swipe left, red
                            // Must be >= operator so that there is no "red flash" when card moves back to middle after aborted swipe right gesture
                            .fill(offset.width >= 0 ? Color.green : Color.red)
                )
                // Make card stand out against its background
                .shadow(color: Color.secondary, radius: 5)
            
            VStack {
                
                // Simply show the question OR the answer when accessibility features are being used
                if accessibilityEnabled {

                    if topOfDeck {
                        
                        Text(appState.isShowingAnswer ? card.answer : card.prompt)
                            .font(appState.isShowingAnswer ? .title : .largeTitle)
                            .foregroundColor(appState.isShowingAnswer ? .secondary : .primary)

                    } else {
                        
                        Text(card.prompt)
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                    }

                } else {
                    
                    // Otherwise show both the question and the answer
                    Text(card.prompt)
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                    
                    // Show the answer in a colour that makes it visible
                    if appState.isShowingAnswer && topOfDeck == true {
                        Text(card.answer)
                            .font(.title)
                            .foregroundColor(.secondary)
                    } else {
                        // Show the answer but hide it
                        // This prevents the question from jumping around when the answer is revealed
                        Text(card.answer)
                            .font(.title)
                            .foregroundColor(.primary)
                            .colorInvert()
                    }

                }
                
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 450, height: 250)
        // Rotate the card at 1/5 the distance it has been dragged
        .rotationEffect(.degrees(Double(offset.width / 5)))
        // Move the card at 5 times the distance it has actually been dragged
        // (less dragging required to move away from the stack)
        .offset(x: offset.width * 5, y: 0)
        /*
         Now, the calculation for this view takes a little thinking, and I wouldn’t blame you if you wanted to spin this off into a method rather than putting it inline. Here’s how it works:
         
         We’re going to take 1/50th of the drag amount, so the card doesn’t fade out too quickly.
         We don’t care whether they have moved to the left (negative numbers) or to the right (positive numbers), so we’ll put our value through the abs() function. If this is given a positive number it returns the same number, but if it’s given a negative number it removes the negative sign and returns the same value as a positive number.
         We then use this result to subtract from 2.
         The use of 2 there is intentional, because it allows the card to stay opaque while being dragged just a little. So, if the user hasn’t dragged at all the opacity is 2.0, which is identical to the opacity being 1. If they drag it 50 points left or right, we divide that by 50 to get 1, and subtract that from 2 to get 1, so the opacity is still 1 – the card is still fully opaque. But beyond 50 points we start to fade out the card, until at 100 points left or right the opacity is 0.
         */
        .opacity(2 - Double(abs(offset.width / 50)))
        // Tell VoiceOver that the card is a button when the prompt is showing
        .accessibility(addTraits: appState.isShowingAnswer ? .isStaticText : .isButton)
        /*
         So, we’ve created a property to store the drag amount, and added three modifiers that use the drag amount to change the way the view is rendered. What remains is the most important part: we need to actually attach a DragGesture to our card so that it updates offset as the user drags the card around. Drag gestures have two useful modifiers of their own, letting us attach functions to be triggered when the gesture has changed (called every time they move their finger), and when the gesture has ended (called when they lift their finger).
         
         Both of these functions are handed the current gesture state to evaluate. In our case we’ll be reading the translation property to see where the user has dragged to, and we’ll be using that to set our offset property, but you can also read the start location, predicted end location, and more. When it comes to the ended function, we’ll be checking whether the user moved it more than 100 points in either direction so we can prepare to remove the card, but if they haven’t we’ll set offset back to 0.
         */
        .gesture(
            DragGesture()
                .onChanged { gesture in
            
                    // Allow card to be dragged only if an answer is showing
                    if appState.isShowingAnswer {
                            // Allow the card to move
                            offset = gesture.translation
                        
                            // Get haptic engine ready to do it's thing
                            feedback.prepare()
                        }
                
                    }
            
                .onEnded { _ in
            
                    // Remove the card if user dragged far enough to rigth or left
                    if abs(offset.width) > 100 {
                            
                        // Success feedback on swipe right
                        var isCorrectAnswer = false
                        if offset.width > 0 {
                            isCorrectAnswer = true
                            if playHapticOnCorrectAnswer {
                                feedback.notificationOccurred(.success)
                            }
                        } else {
                            // Error feedback on swipe left
                            if playHapticOnIncorrectAnswer {
                                feedback.notificationOccurred(.error)
                            }
                            
                            // Must reset the view's offset back to CGSize.zero so the view shows up correctly when a card is being recycled!
                            if recycleIncorrectAnswers {
                                offset = .zero
                            }
                        }

                        // Invoke the closure to remove the card, if it was provided, also passing along whether the user answered correctly or not
                        removal?(isCorrectAnswer)
                        
                    } else {
                        
                        // Make the card move back nicely if the user doesn't drag it fully off the screen
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                        
                    }
            
                }
        )
        // When the user taps a card's prompt, show the answer
        .onTapGesture {
            print("tapping on card, card.prompt is \(card.prompt)")
            print("tapping on card, offset is \(offset)")
            appState.isShowingAnswer = true
        }
        
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: Card.example, topOfDeck: true)
    }
}
