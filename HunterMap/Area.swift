//
//  Area.swift
//  HunterMap
//
//  Created by 佐橘　一旗 on 5/14/16.
//  Copyright © 2016 1tsuki. All rights reserved.
//

import Foundation
import RealmSwift

class Area: Object {
    dynamic var areaId: String? = nil
    dynamic var areaName:String? = nil
    dynamic var externalId: String?
    dynamic var prefCd:String? = nil
    let areaType = RealmOptional<Int8>()
    let institution = RealmOptional<Int8>()
    let boundingRectDimension = RealmOptional<Double>()
    let maxLat = RealmOptional<Double>()
    let minLat = RealmOptional<Double>()
    let maxLng = RealmOptional<Double>()
    let minLng = RealmOptional<Double>()
    dynamic var listedDate: NSDate? = nil
    dynamic var delistedDate: NSDate? = nil
    let coordinates = List<Coordinate>()
    
    override static func primaryKey() -> String? {
        return "areaId"
    }
}