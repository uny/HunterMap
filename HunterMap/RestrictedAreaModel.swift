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
    case Hokkaido = "A15-09_01_WildlifePreserve"
    case Aomori = "A15-09_02_WildlifePreserve"
    case Iwate = "A15-09_03_WildlifePreserve"
    case Miyagi = "A15-09_04_WildlifePreserve"
    case Akita = "A15-09_05_WildlifePreserve"
    case Yamagata = "A15-09_06_WildlifePreserve"
    case Fukushima = "A15-09_07_WildlifePreserve"
    case Ibaraki = "A15-09_08_WildlifePreserve"
    case Tochigi = "A15-09_09_WildlifePreserve"
    case Gumma = "A15-09_10_WildlifePreserve"
    case Saitama = "A15-09_11_WildlifePreserve"
    case Chiba = "A15-09_12_WildlifePreserve"
    case Tokyo = "A15-09_13_WildlifePreserve"
    case Kanagawa = "A15-09_14_WildlifePreserve"
    case Nigata = "A15-09_15_WildlifePreserve"
    case Toyama = "A15-09_16_WildlifePreserve"
    case Ishikawa = "A15-09_17_WildlifePreserve"
    case Fukui = "A15-09_18_WildlifePreserve"
    case Yamanashi = "A15-09_19_WildlifePreserve"
    case Nagano = "A15-09_20_WildlifePreserve"
    case Gifu = "A15-09_21_WildlifePreserve"
    case Shizuoka = "A15-09_22_WildlifePreserve"
    case Aichi = "A15-09_23_WildlifePreserve"
    case Mie = "A15-09_24_WildlifePreserve"
    case Shiga = "A15-09_25_WildlifePreserve"
    case Kyoto = "A15-09_26_WildlifePreserve"
    case Osaka = "A15-09_27_WildlifePreserve"
    case Hyogo = "A15-09_28_WildlifePreserve"
    case Nara = "A15-09_29_WildlifePreserve"
    case Wakayama = "A15-09_30_WildlifePreserve"
    case Tottori = "A15-09_31_WildlifePreserve"
    case Shimane = "A15-09_32_WildlifePreserve"
    case Okayama = "A15-09_33_WildlifePreserve"
    case Hiroshima = "A15-09_34_WildlifePreserve"
    case Yamaguchi = "A15-09_35_WildlifePreserve"
    case Tokushima = "A15-09_36_WildlifePreserve"
    case Kagawa = "A15-09_37_WildlifePreserve"
    case Ehime = "A15-09_38_WildlifePreserve"
    case Kochi = "A15-09_39_WildlifePreserve"
    case Fukuoka = "A15-09_40_WildlifePreserve"
    case Saga = "A15-09_41_WildlifePreserve"
    case Nagasaki = "A15-09_42_WildlifePreserve"
    case Kumamoto = "A15-09_43_WildlifePreserve"
    case Oita = "A15-09_44_WildlifePreserve"
    case Miyazaki = "A15-09_45_WildlifePreserve"
    case Kagoshima = "A15-09_46_WildlifePreserve"
    case Okinawa = "A15-09_47_WildlifePreserve"
    static let entries = [Hokkaido, Aomori, Iwate, Miyagi, Akita, Yamagata, Fukushima, Ibaraki, Tochigi, Gumma, Saitama, Chiba, Tokyo, Kanagawa, Nigata, Toyama, Ishikawa, Fukui, Yamanashi, Nagano, Gifu, Shizuoka, Aichi, Mie, Shiga, Kyoto, Osaka, Hyogo, Nara, Wakayama, Tottori, Shimane, Okayama, Hiroshima, Yamaguchi, Tokushima, Kagawa, Ehime, Kochi, Fukuoka, Saga, Nagasaki, Kumamoto, Oita, Miyazaki, Kagoshima, Okinawa]
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
    let dimention: Double
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
        reload()
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
    
    
    func getAll(loadFromSource: Bool = false) -> [RestrictedArea] {
        if loadFromSource {
            reload()
        }
        return restrictedAreas
    }
        
    func getByRegion(region: MKCoordinateRegion, limit: Int = 30) -> [RestrictedArea] {
        let regionMaxLat = region.center.latitude + region.span.latitudeDelta / 2.0
        let regionMinLat = region.center.latitude - region.span.latitudeDelta / 2.0
        let regionMaxLng = region.center.longitude + region.span.longitudeDelta / 2.0
        let regionMinLng = region.center.longitude - region.span.longitudeDelta / 2.0
        
        let targetAreas = restrictedAreas
            .filter({$0.minLat < regionMaxLat})
            .filter({$0.maxLat > regionMinLat})
            .filter({$0.minLng < regionMaxLng})
            .filter({$0.maxLng > regionMinLng})
        let count = min(targetAreas.count, limit)
        return Array(targetAreas[0..<count])
        
    }
    
    private func reload() {
        restrictedAreas.removeAll()
        for shapeFile in ShapeFiles.entries {
            restrictedAreas.appendContentsOf(loadFromSource(shapeFile.rawValue))
        }
        restrictedAreas.sortInPlace({ $0.0.dimention > $0.1.dimention })
    }
    
    private func loadFromSource(resourceName: String) -> [RestrictedArea] {
        var areas = [RestrictedArea]()
        
        func handler(args: ShapeFileHandlerArgs) -> Void {
            let area = RestrictedArea(coordinates: args.coordinates,
                                      maxLat: args.maxLat,
                                      minLat: args.minLat,
                                      maxLng: args.maxLng,
                                      minLng: args.minLng,
                                      dimention:  args.dimension,
                                      id: getIntFieldValue(kFieldNameId, dbf: args.dbf, shpObject: args.shpObject),
                                      pref: getIntFieldValue(kFieldNamePref, dbf: args.dbf, shpObject: args.shpObject),
                                      areaType: getIntFieldValue(kFieldNameAreaType, dbf: args.dbf, shpObject: args.shpObject),
                                      institution: getIntFieldValue(kFieldNameInstitution, dbf: args.dbf, shpObject: args.shpObject),
                                      areaName: getStringFieldValue(kFieldNameAreaName, dbf: args.dbf, shpObject: args.shpObject),
                                      listedDate: getStringFieldValue(kFieldNameListedDate, dbf: args.dbf, shpObject: args.shpObject),
                                      delistedDate: getStringFieldValue(kFieldNameDelistedDate, dbf: args.dbf, shpObject: args.shpObject))
            areas.append(area)
        }
        
        let path = ShapeFileUtil.getResourcePathForShapeLib(resourceName)
        ShapeFileUtil.loadShapeFile(path, handler: handler)
        
        return areas
    }
    
    private func isLarger(a: RestrictedArea, b: RestrictedArea) -> Bool {
        let sizeA = (a.maxLat - a.minLat) * (a.maxLng - a.minLng)
        let sizeB = (b.maxLat - b.minLat) * (b.maxLng - b.minLng)
        return sizeA > sizeB
    }
    
    private func getStringFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> String? {
        let fieldIndex = DBFGetFieldIndex(dbf, fieldName)
        return String.fromCString(DBFReadStringAttribute(dbf, shpObject.nShapeId, fieldIndex))
    }
    
    private func getIntFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> Int {
        return Int(DBFReadIntegerAttribute(dbf, shpObject.nShapeId, DBFGetFieldIndex(dbf, fieldName)))
    }
}