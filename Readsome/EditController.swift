//
//  EditController.swift
//  Readsome
//
//  Created by Sorgente Fabrizio on 08/03/18.
//  Copyright © 2018 Readsome. All rights reserved.
//

import UIKit
import TesseractOCR
import GPUImage

class EditController : UITableViewController, UITextFieldDelegate, G8TesseractDelegate {

    @IBOutlet weak var scannedTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedImage : UIImage?
    var scannedText : String?
    
    ///////////////////////////////      todo: make it working  ////////////////////////////
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        self.tableView.isScrollEnabled = false
        let newImageView = UIImageView(image: imageView.image)
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        var newScrollView = UIScrollView()
        newScrollView.frame = view.frame
        newImageView.frame = newScrollView.frame
        newScrollView.backgroundColor = tableView.backgroundColor
        
        //        tableView.autoresizesSubviews = true
        self.tableView.addSubview(newScrollView)
        
        
        newScrollView.isScrollEnabled = true
        newScrollView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        newScrollView.addGestureRecognizer(tap)
        newScrollView.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.tableView.isScrollEnabled = true
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        sender.view?.removeFromSuperview()
    }
    //////////////////////////////////////////////////////////////////////////////////////////
    
    override func viewDidAppear(_ animated: Bool) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.image = self.selectedImage
//      Create a new concurrent thread to perform the Image Recognition
        let concurrentQueue = DispatchQueue(label: "imageRecognition", attributes: .concurrent)
        concurrentQueue.async {
            self.performImageRecognition(self.selectedImage!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleTextField.delegate = self

        // Hide the keyboard when tapping outside the field
        self.hideKeyboard()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem : .done, target : self, action : #selector(saveScannedText))
        
        // Add some padding to the text containers
        scannedTextView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTextField.delegate = self
        titleTextField.returnKeyType = .done
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc private func saveScannedText() {
        if let selectedTitle = titleTextField.text, let scannedText = scannedTextView.text, !selectedTitle.isEmpty, !scannedText.isEmpty {
            ScannedTextManager.add(title : selectedTitle, text : scannedText, image : imageView.image!)
            navigationController?.popViewController(animated: true)
        } else {
            let title = NSLocalizedString("Incomplete fields", comment : "String used for the alert dialog shown when the user tries to add an empty scanned text or without a title")
            let message = NSLocalizedString("You have to select a title and keep some text in the scanned field", comment : "String presented in the alert dialog shown when the user tries to add an empty scanned text without a title.")
            
            // Set an "OK" action for the dialog
            let alert = UIAlertController(title : title, message : message, preferredStyle : .alert)
            alert.addAction(UIAlertAction(title: "OK", style : .default, handler : nil))
            
            // Show the alert dialog
            self.present(alert, animated : true, completion : nil)
        }
    }
    

    func performImageRecognition(_ image : UIImage) {
        
        
        let tesseract = G8Tesseract(language: "eng", engineMode: .tesseractOnly)
        tesseract?.delegate = self
        
        let imageTemp = image.g8_blackAndWhite()
        
        
        let imagePreProcessed = self.processImage(inputImage: imageTemp!)
        
        // tesseract.engineMode = .tesseractCubeCombined
        tesseract?.image = imagePreProcessed
        tesseract?.pageSegmentationMode = G8PageSegmentationMode(rawValue: 1)!
        tesseract?.recognize()
        
        var text = tesseract?.recognizedText
        
        // Remove breaks
        text = text?.replacingOccurrences(of: "-\n", with: "")
        text = text?.replacingOccurrences(of: "–\n", with: "")
        text = text?.replacingOccurrences(of: "—\n", with: "")
        text = text?.replacingOccurrences(of: "―\n", with: "")
        
        // Put a placeholder where empty lines are found
        text = text?.replacingOccurrences(of: "\n\n", with: "$R_NL#")
        
        // Remove new lines
        text = text?.replacingOccurrences(of: "\n", with: " ")
        
        // Restore empty lines
        text = text?.replacingOccurrences(of: "$R_NL#", with: "\n\n")
        
        //      Touching the UI in the main thread
        DispatchQueue.main.sync {
//            This instruction show the pre processed image in the imageView
//            self.imageView.image = imagePreProcessed
            
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
            self.scannedTextView.text = text
        }
    }
    
    
    func processImage(inputImage : UIImage) -> UIImage {
        return inputImage
    }

}
