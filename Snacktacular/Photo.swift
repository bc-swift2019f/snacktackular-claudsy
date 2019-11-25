//
//  Photo.swift
//  Snacktacular
//
//  Created by Claudia Yang on 11/10/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Photo {
    var image: UIImage
    var description: String
    var postedBy: String
    var date: Date
    var documentUUID: String // Universal Unique Identifier
    var dictionary: [String: Any]{
        return ["description": description, "postedBy": postedBy, "date": date]
    }
    
    init(image: UIImage, description: String, postedBy: String, date: Date, documentUUID: String) {
        self.image = image
        self.description = description
        self.postedBy = postedBy
        self.date = date
        self.documentUUID = documentUUID
    }
    
    convenience init() {
        let postedBy = Auth.auth().currentUser?.email ?? "Unknown User"
        self.init(image: UIImage(), description: "", postedBy: postedBy, date: Date(), documentUUID: "")
    }
 
    convenience init(dictionary: [String: Any]){
        let description = dictionary["description"] as! String? ?? ""
        let postedBy = dictionary["postedBy"] as! String? ?? ""
        //        let date = dictionary["date"] as! Date? ?? Date()
        let time = dictionary["date"] as! Timestamp?
        let date = time?.dateValue() ?? Date()
        //        let timeIntervalDate = dictionary["date"] as! TimeInterval? ?? TimeInterval()
        //        let date = Date(timeIntervalSince1970: timeIntervalDate)
        self.init(image: UIImage(), description: description, postedBy: postedBy, date: date, documentUUID: "")
    }
    
    func saveData(spot: Spot, completed: @escaping (Bool) -> ()){
        let db = Firestore.firestore()
        let storage = Storage.storage()
        //convert photo.image to a Data type so it canbe saved by Firebase Storage
        guard let photoData = self.image.jpegData(compressionQuality: 0.5) else{
            print("ERROR: could not convert image to dama format")
            return completed(false)
        }
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        documentUUID = UUID().uuidString //generate a unique ID to use for the photo image's name
        //create a ref to upload storage to spot.documentUUID's folder(bucker). w the name we created
        let storageRef = storage.reference().child(spot.documentID).child(self.documentUUID)
        let uploadTask = storageRef.putData(photoData, metadata: uploadMetaData){
            metadata, error in
            guard error == nil else{
                print("ERROR: during .put data storage upload for reference \(storageRef) ERROR \(error! .localizedDescription)")
                return
            }
            print("upload worked! Metadata is \(metadata)")
        }
        uploadTask.observe(.success) { (snapshot) in
            //create dictionary representing the data we want to save
            let dataToSave = self.dictionary
            //this will either create a new doc at documentUUID or update the existing doc
            let ref = db.collection("spots").document(spot.documentID).collection("photos").document(self.documentUUID)
            ref.setData(dataToSave){(error) in
                if let error = error{
                    print("error updateding doc \(self.documentUUID) in spot \(spot.documentID) \(error.localizedDescription)")
                    completed(false)
                }
                else{
                    print("document updated with ref DI \(ref.documentID)")
                    completed(true)
                }
            }
        }
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error{
                print("ERROR: upload task for file \(self.documentUUID) failed in spot \(spot.documentID)")
            }
            return completed(false)
        }
        
    }
    
}


