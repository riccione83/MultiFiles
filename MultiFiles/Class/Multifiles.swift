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
    func updateProgressBar(bytesWritten:NSInteger,totalBytesWritten:NSInteger, totalBytesExpectedToWrite:NSInteger)
    func deleteUploadBar(refreshData:Bool)
    func refreshUserData()
}

@objc class MultifilesHelper: NSObject {
    
    let websiteName = "http://multifiles.herokuapp.com/API/login.php"
    let deleteFileAPI = "http://multifiles.herokuapp.com/API/upload.php"
    let uploadURL = "http://multifiles.herokuapp.com/API/upload.php"
    let fileListAPI = "http://multifiles.herokuapp.com/API/user.php"
    let userUtilsHelperAPI = "http://multifiles.herokuapp.com/API/utils.php"
    let ratingFileAPI = "http://multifiles.herokuapp.com/API/rate.php"
    let renameFileAPI = "http://multifiles.herokuapp.com/API/rename.php"
    let registerNewUserAPI = "http://multifiles.herokuapp.com/API/register.php"
    
    var delegate:UpdateUploadBarDelegate? = nil
    
    func showLoadingHUD() {
        let hud = MBProgressHUD.showHUDAddedTo(self.delegate!.getMainView(), animated: true)
        hud.labelText = "Please wait..."
    }
    
    func hideLoadingHUD() {
        MBProgressHUD.hideAllHUDsForView(self.delegate!.getMainView(), animated: true)
    }
    
    func getUserSpace(userID:String, completition:(spaceUsed:String,success:Bool) -> () ) {
        
        let parameters = ["user_id": userID,
                          "getusedspace":"true"]
        
        Alamofire.request(.POST, userUtilsHelperAPI, parameters: parameters)
            .responseJSON { response in
                
                if let jsonData = response.result.value {
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(spaceUsed: message,success: false)
                    }
                    else if let user_id = json["used_space"].string {
                        print(user_id)
                        completition(spaceUsed: "\(user_id)",success: true)
                    }
                }
        }
    }    
    
    func getFileListForUser(completition:(success:Bool, jsonData:AnyObject?) -> ()) {
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, fileListAPI, parameters: [:])
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    //print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(success: false,jsonData: nil)
                    }
                    else {
                            completition(success: true, jsonData: jsonData)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    
    func registerNewUser(userName:String,userPassword:String,userPasswordRepeat:String,userEmail:String, completition:(message:String,success:Bool) -> ()) {
        
        let parameters = ["user_name": userName,
                          "user_password_new": userPassword,
                          "user_password_repeat": userPasswordRepeat,
                          "user_email": userEmail]
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, registerNewUserAPI, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(message: message,success: false)
                    }
                    else if let message = json["message"].string {
                        completition(message: message, success: true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    
    func renameFile(fileName:String,newFileName:String, completition:(success:Bool) -> ()) {
        
        let parameters = ["file_name": fileName,
                          "new_file_name": newFileName]
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, renameFileAPI, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(success: false)
                    }
                    else {
                        completition(success: true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func setRateForFile(filePath:String,rating:String,userID:String, completition:(success:Bool) -> ()) {
        let parameters = ["file_id": filePath,
                          "set_rate": rating,
                          "user_id": userID]
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, ratingFileAPI, parameters: parameters)
            .responseJSON { response in
                
                print(response.result.value)
                
                if let jsonData = response.result.value {
                    
                    print("JSON: \(jsonData)")
                    let json = JSON(jsonData)
                    
                    if let message = json["error"].string {
                        print(message)
                        completition(success: false)
                    }
                    else if let user_id = json["response"].string {
                        print(user_id)
                        completition(success: true)
                    }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func deleteFile(filePath:String, completition:(success:Bool) -> ()) {
        let parameters = ["delete_file": "1",
                          "file_name": filePath]
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, deleteFileAPI, parameters: parameters)
            .responseJSON { response in
                if let jsonData = response.result.value {

                        print("JSON: \(jsonData)")
                        let json = JSON(jsonData)
                        
                        if let message = json["error"].string {
                            print(message)
                            completition(success: false)
                        }
                        else if let user_id = json["message"].string {
                            print(user_id)
                            completition(success: true)
                        }
                    
                }
                self.hideLoadingHUD()
        }
    }
    
    func login(userName:String, password:String, completition:(user_id:String,success:Bool) -> () ) {
        
        let parameters = ["user_name": userName,
                          "user_password": password]
        
        self.showLoadingHUD()
        
        Alamofire.request(.POST, websiteName, parameters: parameters)
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
                        completition(user_id: message,success: false)
                    }
                    else if let user_id = json["success"].int {
                        print(user_id)
                        completition(user_id: "\(user_id)",success: true)
                    }
                }
                
                self.hideLoadingHUD()
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
