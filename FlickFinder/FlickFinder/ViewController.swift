import UIKit

class ViewController: UIViewController {

    var keyboardOnScreen = false

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latLonSearchButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }

    @IBAction func searchByPhrase(_ sender: AnyObject) {
        userDidTapView(self)
        setUIEnabled(false)

        if !phraseTextField.text!.isEmpty {
            photoTitleLabel.text = "Searching..."

            var methodParameters = createBaseMethodParameters()
            methodParameters[Constants.FlickrParameterKeys.Text] = phraseTextField.text!
            displayImageFromFlickrBySearch(methodParameters)
        } else {
            setUIEnabled(true)
            photoTitleLabel.text = "Phrase Empty."
        }
    }

    @IBAction func searchByLatLon(_ sender: AnyObject) {
        userDidTapView(self)
        setUIEnabled(false)

        if isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange) && isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange) {
            photoTitleLabel.text = "Searching..."

            var methodParameters = createBaseMethodParameters()
            methodParameters[Constants.FlickrParameterKeys.BoundingBox] = boundingBoxText()
            displayImageFromFlickrBySearch(methodParameters)
        } else {
            setUIEnabled(true)
            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
        }
    }

    private func displayImageFromFlickrBySearch(_ methodParameters: [String: String?]) {
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))

        session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                self.show(error: error!.localizedDescription)
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode < 300 else {
                self.show(error: "Uncool status response :(")
                return
            }

            guard let data = data else {
                self.show(error: "No data returned :(")
                return
            }

            let parsedDataOptional = self.parse(data: data)
            guard let parsedData = parsedDataOptional else {
                self.show(error: "Unable to parse data :(")
                return
            }

            guard let flickrStatus = parsedData[Constants.FlickrResponseKeys.Status] as? String, flickrStatus == Constants.FlickrResponseValues.OKStatus else {
                self.show(error: "Flickr API returned error. See error code and message in \(parsedData)")
                return
            }

            print(parsedData)
        }.resume()
    }

    private func parse(data: Data) -> [String: AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
        } catch {
            self.show(error: "unable to parse data as JSON")
            return nil
        }
    }

    private func showData() {

    }

    func show(error: String) {
        print(error)
        performUIUpdatesOnMain {
            self.setUIEnabled(true)
            self.photoTitleLabel.text = "Error occurred, try again."
            self.photoImageView.image = nil
        }
    }

    private func flickrURLFromParameters(_ parameters: [String: String?]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()

        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value!)")
            components.queryItems!.append(queryItem)
        }

        print(components.url!)
        return components.url!
    }

    private func createBaseMethodParameters() -> [String: String] {
        return [
                Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
    }

    private func boundingBoxText() -> String {
        guard let latitude = Double(latitudeTextField.text!), let longitude = Double(longitudeTextField.text!) else {
            return "0,0,0,0"
        }
        return boundingBoxText(longitude: longitude, latitude: latitude)
    }

    private func boundingBoxText(longitude: Double, latitude: Double) -> String {
        let minLongitude = max(Constants.Flickr.SearchLonRange.0, longitude - Constants.Flickr.SearchBBoxHalfWidth)
        let minLatitude = max(Constants.Flickr.SearchLatRange.0, latitude - Constants.Flickr.SearchBBoxHalfHeight)
        let maxLongitude = min(Constants.Flickr.SearchLonRange.1, longitude + Constants.Flickr.SearchBBoxHalfWidth)
        let maxLatitude = min(Constants.Flickr.SearchLatRange.1, latitude + Constants.Flickr.SearchBBoxHalfHeight)
        return "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }

    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }

    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
    }

    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }

    func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }

    func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    @IBAction func userDidTapView(_ sender: AnyObject) {
        resignIfFirstResponder(phraseTextField)
        resignIfFirstResponder(latitudeTextField)
        resignIfFirstResponder(longitudeTextField)
    }

    func isTextFieldValid(_ textField: UITextField, forRange: (Double, Double)) -> Bool {
        if let value = Double(textField.text!), !textField.text!.isEmpty {
            return isValueInRange(value, min: forRange.0, max: forRange.1)
        } else {
            return false
        }
    }

    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
}

private extension ViewController {

    func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseSearchButton.isEnabled = enabled
        latLonSearchButton.isEnabled = enabled

        if enabled {
            phraseSearchButton.alpha = 1.0
            latLonSearchButton.alpha = 1.0
        } else {
            phraseSearchButton.alpha = 0.5
            latLonSearchButton.alpha = 0.5
        }
    }
}

private extension ViewController {

    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }

    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
