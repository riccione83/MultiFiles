//
//  Multifiles.swift
//  MultiFiles
//
//  Created by Riccardo Rizzo on 28/05/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import SwiftyJSON

@objc protocol UpdateUploadBarDelegate {
    func getMainView() -> UIView
    func createUploadBar()
    func updateProgressBar(percentage:Double)
    func deleteUploadBar(refreshData:Bool)
    func refreshUserData()
}

@objc public class MultifilesHelper: NSObject {
    
    let websiteName = "http://multifiles.herokuapp.com/API/login.php"
    let deleteFileAPI = "http://multifiles.herokuapp.com/API/upload.php"
    let uploadURL = "http://multifiles.herokuapp.com/API/upload.php"
    let fileListAPI = "http://multifiles.herokuapp.com/API/user.php"
    let userUtilsHelperAPI = "http://multifiles.herokuapp.com/API/utils.php"
    let ratingFileAPI = "http://multifiles.herokuapp.com/API/rate.php"
    let renameFileAPI = "http://multifiles.herokuapp.com/API/rename.php"
    let registerNewUserAPI = "http://multifiles.herokuapp.com/API/register.php"
    
    var delegate:UpdateUploadBarDelegate?
    
    func showLoadingHUD() {
        
        let hud = MBProgressHUD.showAdded(to: self.delegate?.getMainView(), animated: true)
        hud?.labelText = "Please wait..."
    }
    
    func hideLoadingHUD() {
        MBProgressHUD.hideAllHUDs(for: self.delegate?.getMainView(), animated: true)
    }
    
    func getUserSpace(userID:String, completition:@escaping (_ spaceUsed:String,_ success:Bool) -> () ) {
        
        let parameters = ["user_id": userID,
                          "getusedspace":"true"]
        
        
        Alamofire.request(userUtilsHelperAPI, method: .post, parameters: parameters)
            .responseJSON { response in
                
                if let jsonData = response.result.value {
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(message,false)
                    }
                    else if let user_id = json["used_space"].string {
                        print(user_id)
                        completition("\(user_id)",true)
                    }
                }
        }
    }
    
    func getFileListForUser(completition:@escaping (_ success:Bool, _ jsonData:AnyObject?) -> ()) {
        
        self.showLoadingHUD()
        
        Alamofire.request(fileListAPI, method: .post, parameters: [:])
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    //print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(false,nil)
                    }
                    else {
                        completition(true, jsonData as AnyObject)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    
    func registerNewUser(userName:String,userPassword:String,userPasswordRepeat:String,userEmail:String, completition:@escaping (_ message:String,_ success:Bool) -> ()) {
        
        let parameters = ["user_name": userName,
                          "user_password_new": userPassword,
                          "user_password_repeat": userPasswordRepeat,
                          "user_email": userEmail]
        
        self.showLoadingHUD()
        
        Alamofire.request(registerNewUserAPI, method: .post, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(message,false)
                    }
                    else {
                        completition("", true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    
    func renameFile(fileName:String,newFileName:String, completition:@escaping (_ success:Bool) -> ()) {
        
        let parameters = ["file_name": fileName,
                          "new_file_name": newFileName]
        
        self.showLoadingHUD()
        
        Alamofire.request(renameFileAPI, method: .post, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(false)
                    }
                    else {
                        completition(true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func setRateForFile(filePath:String,rating:String,userID:String, completition:@escaping (_ success:Bool) -> ()) {
        let parameters = ["file_id": filePath,
                          "set_rate": rating,
                          "user_id": userID]
        
        self.showLoadingHUD()
        
        Alamofire.request(ratingFileAPI, method: .post, parameters: parameters)
            .responseJSON { response in
                
                print(response.result.value as Any)
                
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(false)
                    }
                    else if let user_id = json["response"].string {
                        print(user_id)
                        completition(true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func deleteFile(filePath:String, completition:@escaping (_ success:Bool) -> ()) {
        let parameters = ["delete_file": "1",
                          "file_name": filePath]
        
        self.showLoadingHUD()
        
        Alamofire.request(deleteFileAPI, method: .post, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(false)
                    }
                    else if let user_id = json["message"].string {
                        print(user_id)
                        completition(true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func login(userName:String, password:String, completition:@escaping (_ user_id:String,_ success:Bool) -> () ) {
        
        let parameters = ["user_name": userName,
                          "user_password": password]
        
        self.showLoadingHUD()
        
        Alamofire.request(websiteName, method: .post, parameters: parameters)
            .responseJSON { response in
                /*print(response.request)  // original URL request
                 print(response.response) // URL response
                 print(response.data)     // server data
                 print(response.result)   // result of response serialization*/
                
                if let jsonData = response.result.value {
                    //print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(message,false)
                    }
                    else if let user_id = json["success"].int {
                        print(user_id)
                        completition("\(user_id)",true)
                    }
                }
                
                self.hideLoadingHUD()
        }
    }
    
    func setDelegate(delegate: UpdateUploadBarDelegate) {
        self.delegate = delegate
    }
    
    func upload(filePath:NSURL) {
        
        let theFileName = filePath.lastPathComponent
        //let url:URL = URL(fileURLWithPath: filePath.absoluteString!)
        let imageData:Data = try! Data.init(contentsOf: filePath as URL)  // .dataWithContentsOfMappedFile("\(filePath)")
        
        self.delegate?.createUploadBar()
        
        let url_ = try! URLRequest(url: URL(string:uploadURL)!, method: .post, headers: nil)

        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "file", fileName: theFileName!, mimeType: "multipart/form-data")
        },
         with: url_,
         
         encodingCompletion: { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    self.delegate?.deleteUploadBar(refreshData: true)
                    print(response.result)   // result of response serialization
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                }
                upload.uploadProgress { progress in
                    
                    print(progress.fractionCompleted)
                    
                    //let progress = Float(progress.fractionCompleted)*100
                    self.delegate?.updateProgressBar(percentage: progress.fractionCompleted)
                    print("Uploading: \(progress)%")
                    // progress block
 
                }
            case .failure(let encodingError):
                self.delegate?.deleteUploadBar(refreshData: true)
                print(encodingError)
            }
        })
    
   /*     Alamofire.upload(
            uploadURL,
            .POST,
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
 */
    }
    
}
