//
//  animals.playground
//  iOS Networking
//
//  Created by Jarrod Parkes on 09/30/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import Foundation

/* Path for JSON files bundled with the Playground */
var pathForAnimalsJSON = Bundle.main.path(forResource: "animals", ofType: "json")

/* Raw JSON data (...simliar to the format you might receive from the network) */
var rawAnimalsJSON = try? Data(contentsOf: URL(fileURLWithPath: pathForAnimalsJSON!))

/* Error object */
var parsingAnimalsError: NSError? = nil

/* Parse the data into usable form */
var parsedAnimalsJSON = try! JSONSerialization.jsonObject(with: rawAnimalsJSON!, options: .allowFragments) as! NSDictionary

func parseJSONAsDictionary(_ dictionary: NSDictionary) {
    /* Start playing with JSON here... */
    guard let photos = dictionary["photos"] as? NSDictionary else {
        print("couldn't find \"photos\" inside \(dictionary)")
        return
    }
    
    guard let total = photos["total"] as? Int else {
        print("unknown number of photos")
        return
    }
    
    print("number of photos: \(total)")
}

private func extractTotalOrCrash(_ dictionary: NSDictionary) -> Int throws -> ParsingError {
    guard let total = dictionary["total"] as? Int else {
        throw Error()
    }
    return total
}

class ParsingError : Error {
    
}

parseJSONAsDictionary(parsedAnimalsJSON)
