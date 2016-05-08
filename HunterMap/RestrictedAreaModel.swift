//
//  HuntingAreaModel.swift
//  HunterMap
//
//  Created by 佐橘　一旗 on 5/8/16.
//  Copyright © 2016 1tsuki. All rights reserved.
//

import Foundation
import MapKit
import shapelib

enum ShapeFiles: String {
    case Kanagawa = "A15-09_14_WildlifePreserve"
}

enum AreaType: Int {
    case WildlifeProtectionArea = 1
    case SpecialProtectionArea = 2
    case GameReserve = 3
    case PaidGameHuntingArea = 8
    case CertainHuntingEquipmentProhibitedArea = 9
}

struct RestrictedArea {
    // defined as variable for MKPolygon, basically its a let
    var coordinates: [CLLocationCoordinate2D]
    let id: Int
    let pref: Int
    let areaType: Int
    let institution: Int
    let areaName: String?
    let listedDate: String?
    let delistedDate: String?
}

class RestrictedAreaModel {
    
    // fieldNames defined in DBF
    static let kFieldNameId = "A15_001"
    static let kFieldNamePref = "A15_002"
    static let kFieldNameInstitution = "A15_003"
    static let kFieldNameAreaType = "A15_004"
    static let kFieldNameAreaName = "A15_005"
    static let kFieldNameListedDate = "A15_006"
    static let kFieldNameDelistedDate = "A15_007"
    
    static func loadRestrictedAreas(shapeFile: ShapeFiles) -> [RestrictedArea] {
        var restrictedAreas = [RestrictedArea]()
        
        func handler(coordinates: [CLLocationCoordinate2D], shpObject: SHPObject, dbf: DBFHandle) -> Void {
            let area = RestrictedArea(coordinates: coordinates,
                                      id: getIntFieldValue(kFieldNameId, dbf: dbf, shpObject: shpObject),
                                      pref: getIntFieldValue(kFieldNamePref, dbf: dbf, shpObject: shpObject),
                                      areaType: getIntFieldValue(kFieldNameAreaType, dbf: dbf, shpObject: shpObject),
                                      institution: getIntFieldValue(kFieldNameInstitution, dbf: dbf, shpObject: shpObject),
                                      areaName: getStringFieldValue(kFieldNameAreaName, dbf: dbf, shpObject: shpObject),
                                      listedDate: getStringFieldValue(kFieldNameListedDate, dbf: dbf, shpObject: shpObject),
                                      delistedDate: getStringFieldValue(kFieldNameDelistedDate, dbf: dbf, shpObject: shpObject))
            restrictedAreas.append(area)
        }
        
        let path = ShapeFileUtil.getResourcePathForShapeLib(shapeFile.rawValue)
        ShapeFileUtil.loadShapeFile(path, handler: handler)
        
        return restrictedAreas
    }
    
    static func getStringFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> String? {
        let fieldIndex = DBFGetFieldIndex(dbf, fieldName)
        return String.fromCString(DBFReadStringAttribute(dbf, shpObject.nShapeId, fieldIndex))
    }
    
    static func getIntFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> Int {
        return Int(DBFReadIntegerAttribute(dbf, shpObject.nShapeId, DBFGetFieldIndex(dbf, fieldName)))
    }
}