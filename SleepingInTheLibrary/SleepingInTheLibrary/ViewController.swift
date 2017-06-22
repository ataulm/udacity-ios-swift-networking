//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func grabNewImage(_ sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
    }
    
    // MARK: Configure UI
    
    private func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        grabImageButton.isEnabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let url = URL(string: Constants.Flickr.APIBaseURL + escapeParams(parameters: methodParameters as [String:AnyObject]))!
        
        let urlRequest = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if (error == nil) {
                if let data = data {
                    let parsedData : [String:AnyObject]!
                    do {
                        parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                    } catch {
                        print("ruhroh, error")
                        return
                    }
                    
                    if let photosDictionaries = parsedData[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                        let photoDictionariesArray = photosDictionaries[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                        let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoDictionariesArray.count)))
                        let randomPhoto = photoDictionariesArray[randomPhotoIndex] as [String:AnyObject]
                        
                        if let imageUrlString = randomPhoto[Constants.FlickrResponseKeys.MediumURL] as? String,
                            let title = randomPhoto[Constants.FlickrResponseKeys.Title] as? String {
                            print("title: \(title), image url: \(imageUrlString)")
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func escapeParams(parameters: [String:AnyObject]) -> String {
        if (parameters.isEmpty) {
            return ""
        } else {
            var keyValuePairs = [String]()
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                keyValuePairs.append(key + "=\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
}
