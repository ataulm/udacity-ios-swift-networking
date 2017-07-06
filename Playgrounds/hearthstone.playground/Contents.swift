//
//  hearthstone.playground
//  iOS Networking
//
//  Created by Jarrod Parkes on 09/30/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import Foundation

/* Path for JSON files bundled with the Playground */
let pathForHearthstoneJSON = Bundle.main.path(forResource: "hearthstone", ofType: "json")

/* Raw JSON data (...simliar to the format you might receive from the network) */
let rawHearthstoneJSON = try? Data(contentsOf: URL(fileURLWithPath: pathForHearthstoneJSON!))

/* Error object */
var parsingHearthstoneError: NSError? = nil

/* Parse the data into usable form */
var parsedHearthstoneJSON = try! JSONSerialization.jsonObject(with: rawHearthstoneJSON!, options: .allowFragments) as! NSDictionary

func parseJSONAsDictionary(_ dictionary: NSDictionary) {
    let elements = dictionary["Basic"] as! [[String:AnyObject]]
    var minionsWithCostOfFive = 0
    var weaponsDurabilityOfTwo = 0
    var minionsHaveBattlecryEffectMentioned = 0
    var numberCommonMinions = 0
    var costCommonMinions = 0
    var sumStatsToRatioCost:Double = 0.0
    var numberMinionsWithNonZeroCost = 0
    
    for (_, element) in elements.enumerated() {
        if (element["type"]!.isEqual(to: "Minion")) {
            if let cost = element["cost"] as? Int {
                if (cost != 0) {
                    numberMinionsWithNonZeroCost += 1
                    sumStatsToRatioCost += statsToCostRatio(attack: element["attack"] as! Int, health: element["health"] as! Int, cost: cost)
                    print(sumStatsToRatioCost)
                }
                
                if let rarity = element["rarity"] as? String, rarity.isEqual("Common") {
                    numberCommonMinions += 1
                    costCommonMinions += cost
                }
                
                if (cost == 5) {
                    minionsWithCostOfFive += 1
                }
            }
            
            if let text = element["text"] as? String {
                if (text.contains("Battlecry")) {
                    minionsHaveBattlecryEffectMentioned += 1
                }
            }
        }
        
        if (element["type"]!.isEqual(to: "Weapon")) && (element["durability"] as? Int) == 2 {
            weaponsDurabilityOfTwo += 1;
        }
    }
    
    print("how many minions have a cost of 5? \(minionsWithCostOfFive)")
    
    print("how many weapons have a durability of 2? \(weaponsDurabilityOfTwo)")
    
    print("how many minions have a battlecry effect? \(minionsHaveBattlecryEffectMentioned)")
    
    let averageCost = Double(costCommonMinions) / Double(numberCommonMinions)
    print("what is the average cost of Common minions (2dp)? \(formatToTwoDecimalPlaces(averageCost))")
    
    let averageStatsToRatioCost = sumStatsToRatioCost / Double(numberMinionsWithNonZeroCost)
    print("what is the average stats-to-cost-ratio for all minions with a non-zero cost (2dp)? \(formatToTwoDecimalPlaces(averageStatsToRatioCost))")
}

private func formatToTwoDecimalPlaces(_ value: Double) -> String {
    return String(format: "%.2f", value)
}

private func statsToCostRatio(attack: Int, health: Int, cost: Int) -> Double {
    return Double(attack + health) / Double(cost)
}

parseJSONAsDictionary(parsedHearthstoneJSON)
