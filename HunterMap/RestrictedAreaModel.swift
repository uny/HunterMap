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

/**
 * dataSource : http://nlftp.mlit.go.jp/ksj/jpgis/datalist/KsjTmplt-A15.html
 */
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
    let maxLat: Double
    let minLat: Double
    let maxLng: Double
    let minLng: Double
    let id: Int
    let pref: Int
    let areaType: Int
    let institution: Int
    let areaName: String?
    let listedDate: String?
    let delistedDate: String?
}

class RestrictedAreaModel {
    
    // make class singleton
    static var sharedInstance: RestrictedAreaModel = {
        return RestrictedAreaModel()
    }()
    private init() {
        refreshCache()
    }
    
    // fieldNames defined in DBF
    let kFieldNameId = "A15_001"
    let kFieldNamePref = "A15_002"
    let kFieldNameInstitution = "A15_003"
    let kFieldNameAreaType = "A15_004"
    let kFieldNameAreaName = "A15_005"
    let kFieldNameListedDate = "A15_006"
    let kFieldNameDelistedDate = "A15_007"
    
    var restrictedAreas = [RestrictedArea]()
    
    func refreshCache() {
        loadFromSource(ShapeFiles.Kanagawa)
    }
    
    func getAll(loadFromSource: Bool = false) -> [RestrictedArea] {
        if loadFromSource {
            refreshCache()
        }
        return restrictedAreas
    }
    
    func getByRegion(region: MKCoordinateRegion, maxDelta: Double = 10/60) -> [RestrictedArea] {
        let latitudeDelta = min(region.span.latitudeDelta, maxDelta)
        let longitudeDelta = min(region.span.longitudeDelta, maxDelta)
        
        return restrictedAreas
            .filter({$0.maxLat <= region.center.latitude + latitudeDelta})
            .filter({$0.minLat >= region.center.latitude - latitudeDelta})
            .filter({$0.maxLng <= region.center.longitude + longitudeDelta})
            .filter({$0.minLng >= region.center.longitude - longitudeDelta})
    }
    
    private func loadFromSource(shapeFile: ShapeFiles) {
        restrictedAreas.removeAll()
        
        func handler(coordinates: [CLLocationCoordinate2D], shpObject: SHPObject, dbf: DBFHandle) -> Void {
            var maxLat: Double = 0, maxLng: Double = 0, minLat: Double = Double.infinity, minLng: Double = Double.infinity
            for coordinate in coordinates {
                maxLat = max(maxLat, coordinate.latitude)
                maxLng = max(maxLng, coordinate.longitude)
                minLat = min(minLat, coordinate.latitude)
                minLng = min(minLng, coordinate.longitude)
            }
            
            let area = RestrictedArea(coordinates: coordinates,
                                      maxLat: maxLat,
                                      minLat: minLat,
                                      maxLng: maxLng,
                                      minLng: minLng,
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
    }
    
    private func getStringFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> String? {
        let fieldIndex = DBFGetFieldIndex(dbf, fieldName)
        return String.fromCString(DBFReadStringAttribute(dbf, shpObject.nShapeId, fieldIndex))
    }
    
    private func getIntFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> Int {
        return Int(DBFReadIntegerAttribute(dbf, shpObject.nShapeId, DBFGetFieldIndex(dbf, fieldName)))
    }
}