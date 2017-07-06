//
//  achievements.playground
//  iOS Networking
//
//  Created by Jarrod Parkes on 09/30/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import Foundation

/* Path for JSON files bundled with the Playground */
var pathForAchievementsJSON = Bundle.main.path(forResource: "achievements", ofType: "json")

/* Raw JSON data (...simliar to the format you might receive from the network) */
var rawAchievementsJSON = try? Data(contentsOf: URL(fileURLWithPath: pathForAchievementsJSON!))

/* Error object */
var parsingAchivementsError: NSError? = nil

/* Parse the data into usable form */
var parsedAchievementsJSON = try! JSONSerialization.jsonObject(with: rawAchievementsJSON!, options: .allowFragments) as! NSDictionary

private func categoryIdFor(categoryName:String, categories: [[String:AnyObject]]) -> String {
    for category in categories {
        if let title = category["title"], title.isEqual(categoryName) {
            return category["categoryId"] as! String
        }
    }
    return "No category found"
}

func parseJSONAsDictionary(_ dictionary: NSDictionary) {
    let categories = dictionary["categories"] as! [[String:AnyObject]]
    let achievements = dictionary["achievements"] as! [[String:AnyObject]]
    let achievementWithPointValueGreaterThanTen = countAchievementsWithMoreThanTenPoints(achievements: achievements)
    print("How many achievements have a point value greater than 10? \(achievementWithPointValueGreaterThanTen)")
    
    let averagePoints = determineAveragePointsFor(achievements: achievements)
    print("What is the average point value for achievements (2dp)? \(formatToTwoDecimalPlaces(averagePoints))")

    let howToDoCoolRunning = howToWinCoolRunningAchievement(achievements: achievements)
    print("Which mission must you complete to get the `Cool Running` achievement`? \(howToDoCoolRunning)")
    
    let achievementCountMatchmaking = howManyAchievementsInMatchmakingCategory(achievements: achievements, categoryId: categoryIdFor(categoryName: "Matchmaking", categories: categories))
    print("How many achievements belong to the 'Matchmaking' category? \(achievementCountMatchmaking)")
}

private func howToWinCoolRunningAchievement(achievements: [[String:AnyObject]]) -> String {
    for achievement in achievements {
        if let title = achievement["title"] as? String, title.isEqual("Cool Running") {
            return achievement["description"] as! String
        }
    }
    return "Could not find cool running achievement"
}

private func howManyAchievementsInMatchmakingCategory(achievements: [[String:AnyObject]], categoryId: String) -> Int {
    var count = 0
    for achievement in achievements {
        if let thisCategoryId = achievement["categoryId"] as? String, thisCategoryId.isEqual(categoryId) {
            count += 1
        }
    }
    return count
}

private func countAchievementsWithMoreThanTenPoints(achievements: [[String:AnyObject]]) -> Int {
    var count = 0
    for achievement in achievements {
        let points = achievement["points"] as! Int
        if (points > 10) {
            count += 1
        }
    }
    return count
}

private func determineAveragePointsFor(achievements: [[String:AnyObject]]) -> Double {
    var totalPoints = 0
    for achievement in achievements {
        totalPoints += achievement["points"] as! Int
    }
    return Double(totalPoints) / Double(achievements.count)
}

private func formatToTwoDecimalPlaces(_ value: Double) -> String {
    return String(format: "%.2f", value)
}

parseJSONAsDictionary(parsedAchievementsJSON)
