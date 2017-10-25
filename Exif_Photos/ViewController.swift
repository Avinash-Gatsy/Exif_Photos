//
//  ViewController.swift
//  Exif_Photos
//
//  Created by Avinash on 25/10/17.
//  Copyright © 2017 avinash. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
class ViewController: UIViewController {
    private var images : PHFetchResult<AnyObject>!
    
    @IBOutlet weak var ImagePlaceholder: UIImageView!
    @IBOutlet weak var metadataLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //editEXIFData(images: images)
        retrieveMetadata()
    }
    func retrieveMetadata(){
        // Retrieve model from all photos
        images = PHAsset.fetchAssets(with: .image, options: nil) as! PHFetchResult<AnyObject>
        
        // Amount of pictures on the device
        print("Amount of pictures on device: \(images.count)")
        
        // Is the last picture a favoirte?
        (images[images.count-1] as! PHAsset).isFavorite ? print("The last picture is a favorite!") : print("The last picture is not a favorite!")
        
        // Retrieve metadata from the last picture on the device
        let asset = images[images.count-1] as! PHAsset
        
        //Diaplay in UI
        self.ImagePlaceholder.image = getAssetToImage(asset: asset)
            
        asset.requestContentEditingInput(with: nil) { (contentEditingInput: PHContentEditingInput?, _) -> Void in
            //Get full image
            let url = contentEditingInput!.fullSizeImageURL
            let orientation = contentEditingInput!.fullSizeImageOrientation
            var inputImage = CIImage(contentsOf: url!)
            inputImage = inputImage!.oriented(forExifOrientation: orientation)
            let metadata: NSDictionary = inputImage!.properties as NSDictionary
            //print(metadata)
            /** for (key, value) in inputImage!.properties {
                print("\(key):\(value)")
            } **/
            self.metadataLabel.text = self.jsonToString(json: metadata)
        }
    }
    func jsonToString(json: AnyObject) -> String? {
        var outputString = ""
        do {
            let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
            let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
            //print(convertedString ?? "defaultvalue")
            outputString = convertedString!
        } catch let myJSONError {
            print(myJSONError)
        }
        return outputString
    }
    //function to convert PHAsset to UIImage
    func getAssetToImage(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var Image = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            Image = result!
        })
        return Image
    }
    func editEXIFData(images: PHFetchResult<AnyObject>){
        let testImage = getAssetToImage(asset: self.images[self.images.count-1] as! PHAsset)
        let testImageData: Data = UIImageJPEGRepresentation(testImage, 1)!
        
        let cgImgSource: CGImageSource = CGImageSourceCreateWithData(testImageData as CFData, nil)!
        let uti: CFString = CGImageSourceGetType(cgImgSource)!
        let dataWithEXIF: NSMutableData = NSMutableData(data: testImageData)
        let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!
        
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(cgImgSource, 0, nil)! as NSDictionary
        let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
        
        let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
        
        print("before modification \(EXIFDictionary)")
        
        EXIFDictionary[kCGImagePropertyExifUserComment as String] = "edited the User Comment - test"
        mutable[kCGImagePropertyExifDictionary as String] = EXIFDictionary
        
        CGImageDestinationAddImageFromSource(destination, cgImgSource, 0, (mutable as CFDictionary))
        CGImageDestinationFinalize(destination)
        
        let testImageModified: CIImage = CIImage(data: dataWithEXIF as Data, options: nil)!
        let newproperties: NSDictionary = testImageModified.properties as NSDictionary
        
        print("after modification \(newproperties)")
    }
}

