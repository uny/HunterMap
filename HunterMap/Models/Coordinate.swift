//
//  Coordinate.swift
//  HunterMap
//
//  Created by 佐橘　一旗 on 5/14/16.
//  Copyright © 2016 1tsuki. All rights reserved.
//

import Foundation
import MapKit
import RealmSwift


class Coordinate: Object {
    dynamic var area: Area?
    dynamic var latitude: Double = 0
    dynamic var longitude: Double = 0
    
    func getCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
}