//
//  HistoryModel.swift
//  ExerciseApp
//
//  Created by developer on 2/25/21.
//

import UIKit

class HistoryModel: NSObject {
    var name = ""
    var bodyWeight: Int = 0
    var reps: Int = 0
    var date: Date = Date()

    override init() {
        super.init()
    }
    
    init(_ json: [String: Any]) {
        name = json["name"] as? String ?? ""
        bodyWeight = json["bodyWeight"] as? Int ?? 0
        reps = json["reps"] as? Int ?? 0
        date = json["date"] as? Date ?? Date()

    }
}
