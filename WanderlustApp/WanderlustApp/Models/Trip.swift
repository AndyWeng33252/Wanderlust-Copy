//
//  Trip.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 11/1/20.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

public struct Trip: Codable {
    @DocumentID var tripId:String?
    let tripName:String
    let coverPhoto:String
    let userId:String
    let timestamp:Timestamp?
    let entries:[String]?

    enum CodingKeys: String, CodingKey {
        case tripName
        case coverPhoto
        case userId = "userID"
        case timestamp
        case entries
    }

}

func fetchTrip(tripId: String, completion: @escaping (Trip?)->()) {
    db!.collection("trips").document(tripId).getDocument { (document, error) in
        let result = Result {
          try document?.data(as: Trip.self)
        }
        switch result {
        case .success(let trip):
            if let trip = trip {
                print("successful got \(trip)")
                completion(trip)
            } else {
                completion(nil)
                print("Trip does not exist")
            }
        case .failure(let error):
            print("Error decoding user: \(error)")
        }
    }
}




