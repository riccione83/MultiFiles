//
//  Multifiles.swift
//  MultiFiles
//
//  Created by Riccardo Rizzo on 28/05/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

import UIKit
import Alamofire

@objc protocol UpdateUploadBarDelegate {
    func createUploadBar()
    func updateProgressBar(bytesWritten:NSInteger,totalBytesWritten:NSInteger, totalBytesExpectedToWrite:NSInteger)
    func deleteUploadBar(refreshData:Bool)
}

@objc class MultifilesHelper: NSObject {
    
    let websiteName = "http://multifiles.herokuapp.com/API/login.php"
    let uploadURL = "http://multifiles.herokuapp.com/API/upload.php"
    
    var delegate:UpdateUploadBarDelegate? = nil
    
    
    func login(userName:String, password:String) {
        
        let parameters = ["user_name": userName,
                          "user_password": password]
        
        Alamofire.request(.POST, websiteName, parameters: parameters)
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
                
                //self.upload()
        }
    }
    
    func upload(filePath:NSURL) {
        
        let theFileName = filePath.lastPathComponent
        let imageData:NSData = NSData(contentsOfURL: filePath)!// .dataWithContentsOfMappedFile("\(filePath)")

        self.delegate?.createUploadBar()
        
        Alamofire.upload(
            .POST,
            uploadURL,
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: imageData, name: "file", fileName: theFileName!, mimeType: "multipart/form-data")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        self.delegate?.deleteUploadBar(true)
                    }
                    upload.progress { _, totalBytesRead, totalBytesExpectedToRead in
                        let progress = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
                        self.delegate?.updateProgressBar(0, totalBytesWritten: NSInteger(totalBytesRead), totalBytesExpectedToWrite: NSInteger(totalBytesExpectedToRead))
                        print("Uploading: \(progress)%")
                        // progress block
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                    self.delegate?.deleteUploadBar(true)
                }
            }
        )
    }
    
}
