//
//  Entry.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 11/3/20.
//

import MapKit
import FirebaseFirestore
import FirebaseFirestoreSwift

public struct Entry: Codable {
    @DocumentID var entryId:String?
    var coordinates: GeoPoint?
    var coverPhoto: String?
    var description: String?
    var entryName: String?
    var locationName: String?
    var entryOrder: Int?
    var mediaList: [String]?
    
    enum CodingKeys: String, CodingKey {
        case entryId
        case coverPhoto
        case description
        case entryName
        case locationName
        case coordinates
        case entryOrder
        case mediaList
    }
}

func fetchEntry(entryId: String, completion: @escaping (Entry?)->()) {
    db!.collection("entries").document(entryId).getDocument { (document, error) in
        let result = Result {
          try document?.data(as: Entry.self)
        }
        switch result {
        case .success(let entry):
            if let entry = entry {
                print("successful got \(entry)")
                completion(entry)
            } else {
                print("Entry does not exist")
            }
        case .failure(let error):
            print("Error decoding user: \(error)")
        }
    }
}


