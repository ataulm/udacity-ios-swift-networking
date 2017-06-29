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
            
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode < 300 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned :(")
                return
            }
            
            let parsedData: [String:AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Couldn't parse the data as JSON: '\(data)'")
                return
            }
            
            guard let flickrStatus = parsedData[Constants.FlickrResponseKeys.Status] as? String, flickrStatus == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned error. See error code and message in \(parsedData)")
                return
            }
            
            guard let photosDictionary = parsedData[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                displayError("Couldn't find keys \(Constants.FlickrResponseKeys.Photos) and \(Constants.FlickrResponseKeys.Photo) in \(parsedData)")
                return
            }
            
            
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let randomPhoto = photoArray[randomPhotoIndex] as [String:AnyObject]
            let randomPhotoTitle = randomPhoto[Constants.FlickrResponseKeys.Title] as? String
            
            guard let imageUrlString = randomPhoto[Constants.FlickrResponseKeys.MediumURL] as? String else {
                displayError("Couldn't find keys \(Constants.FlickrResponseKeys.MediumURL)")
                return
            }
            
            let imageUrl = URL(string: imageUrlString)
            if let imageData = try? Data(contentsOf: imageUrl!) {
                performUIUpdatesOnMain {
                    self.photoImageView.image = UIImage(data: imageData)
                    self.photoTitleLabel.text = randomPhotoTitle ?? "(Untitled)"
                    self.setUIEnabled(true)
                }
            } else {
                displayError("Image does not exist at \(String(describing: imageUrl))")
            }
                    
            print("title: \(String(describing: randomPhotoTitle)), image url: \(imageUrlString)")
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
