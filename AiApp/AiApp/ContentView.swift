//
//  ContentView.swift
//  AiApp
//
//  Created by Alexander, Marcus J on 4/10/24.
//

import SwiftUI
import Foundation

struct Card: Identifiable, Hashable {
    let id = UUID()
    let suit: String
    let rank: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(suit)
        hasher.combine(rank)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.suit == rhs.suit && lhs.rank == rhs.rank
    }
}

struct ContentView: View {
    @State private var playerCards: [Card] = []
    @State private var computerCards: [[Card]] = []
    @State private var communityCards: [Card] = []
    @State private var playerBet: Int = 0
    @State private var playerMoney: Int = 1000
    @State private var computerMoney: Int = 1000
    @State private var pot: Int = 0
    @State private var isComputerCalling: Bool = false
    @State private var isFolding: Bool = false
    @State private var usedCards: Set<Card> = Set<Card>()
    @State private var winnerIndex: Int? = nil
    @State private var isRiverDealt: Bool = false
    
    let suits = ["♥️", "♦️", "♣️", "♠️"]
    let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    
    func drawCard() -> Card {
        var newCard: Card
        repeat {
            newCard = Card(suit: suits.randomElement()!, rank: ranks.randomElement()!)
        } while usedCards.contains(newCard)
        usedCards.insert(newCard)
        return newCard
    }
    
    func drawCards() {
        playerCards = [drawCard(), drawCard()]
        computerCards = (0..<3).map { _ in [drawCard(), drawCard()] }
    }
    
    func dealFlop() {
        if playerCards.count == 2 {
            communityCards = [drawCard(), drawCard(), drawCard()]
        }
    }
    
    func dealTurn() {
        if playerCards.count == 2 && communityCards.count == 3 {
            communityCards.append(drawCard())
        }
    }
    
    func dealRiver() {
        if playerCards.count == 2 && communityCards.count == 4 {
            communityCards.append(drawCard())
            isRiverDealt = true
            determineWinner()
        }
    }
    
    func computerDecision() {
        isComputerCalling = true
    }
    
    func resetGame() {
        playerCards = []
        computerCards = []
        communityCards = []
        playerBet = 0
        pot = 0
        isComputerCalling = false
        isFolding = false
        usedCards = []
        winnerIndex = nil
        isRiverDealt = false
    }
    
    func evaluateHand(_ hand: [Card]) -> Int {
        // Convert card ranks to integers for easier comparison
        var ranksToInt: [Int] = []
        for card in hand {
            if let rankIndex = ranks.firstIndex(of: card.rank) {
                ranksToInt.append(rankIndex)
            }
        }
        ranksToInt.sort()
        
        // Check for flush
        let flush = hand.allSatisfy { $0.suit == hand[0].suit }
        
        // Check for straight
        var straight = false
        if ranksToInt.count == 5 {
            straight = ranksToInt[0] + 4 == ranksToInt[4] || (ranksToInt == [0, 1, 2, 3, 12]) // Ace can be low for A-2-3-4-5 straight
        }
        
        // Check for royal flush or straight flush
        if flush && straight {
            if ranksToInt == [8, 9, 10, 11, 12] {
                return 9 // Royal Flush
            } else {
                return 8 // Straight Flush
            }
        }
        
        // Check for four of a kind
        var counts: [Int: Int] = [:]
        for rank in ranksToInt {
            counts[rank, default: 0] += 1
        }
        if counts.values.contains(4) {
            return 7 // Four of a Kind
        }
        
        // Check for full house
        if counts.values.contains(3) && counts.values.contains(2) {
            return 6 // Full House
        }
        
        // Check for flush
        if flush {
            return 5 // Flush
        }
        
        // Check for straight
        if straight {
            return 4 // Straight
        }
        
        // Check for three of a kind
        if counts.values.contains(3) {
            return 3 // Three of a Kind
        }
        
        // Check for two pair
        if counts.values.filter({ $0 == 2 }).count == 2 {
            return 2 // Two Pair
        }
        
        // Check for one pair
        if counts.values.contains(2) {
            return 1 // One Pair
        }
        
        // High Card
        return 0
    }
    
    func determineWinner() {
        let playerHand = playerCards + communityCards
        let playerRank = evaluateHand(playerHand)
        var bestRank = playerRank
        var winner = 0
        
        for (index, cards) in computerCards.enumerated() {
            let rank = evaluateHand(cards + communityCards)
            if rank > bestRank {
                bestRank = rank
                winner = index + 1
            }
        }
        
        if bestRank == playerRank {
            winner = 0
        }
        
        winnerIndex = winner
        if winner == 0 {
            playerMoney += pot
        } else {
            computerMoney += pot
        }
    }
    
    var body: some View {
        VStack {
            Text("Computer Players' Cards:")
            ForEach(computerCards.indices, id: \.self) { index in
                HStack {
                    ForEach(computerCards[index], id: \.id) { card in
                        if isRiverDealt {
                            Text("\(card.rank)\(card.suit)")
                                .font(.system(size: 20))
                                .padding(5)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                                .frame(width: 40, height: 60)
                                .padding(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                    if let winner = winnerIndex, winner == index + 1 {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Text("Community Cards:")
            HStack {
                ForEach(communityCards, id: \.id) { card in
                    Text("\(card.rank)\(card.suit)")
                        .font(.system(size: 20))
                        .padding(5)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
            .padding()
            
            Spacer()
            
            Text("Your Cards:")
            HStack {
                ForEach(playerCards, id: \.id) { card in
                    Text("\(card.rank)\(card.suit)")
                        .font(.system(size: 20))
                        .padding(5)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                if let winner = winnerIndex, winner == 0 {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding()
            
            HStack {
                Button("Draw Cards") {
                    drawCards()
                }
                .padding()
                
                Button("Bet 10") {
                    if playerMoney >= 10 {
                        playerBet += 10
                        playerMoney -= 10
                        pot += 10
                        computerDecision()
                    }
                }
                .padding()
                
                Button("Fold") {
                    resetGame()
                    isFolding = true
                }
                .padding()
            }
            
            HStack {
                Button("Deal Flop") {
                    dealFlop()
                }
                .padding()
                .disabled(playerBet == 0 || communityCards.count > 0)
                
                Button("Deal Turn") {
                    dealTurn()
                }
                .padding()
                .disabled(playerBet == 0 || communityCards.count != 3)
                
                Button("Deal River") {
                    dealRiver()
                }
                .padding()
                .disabled(playerBet == 0 || communityCards.count != 4)
            }
            
            Text("Pot: \(pot)")
            
            if isComputerCalling {
                Image(systemName: "hand.thumbsup")
                    .font(.system(size: 30))
                    .padding()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
