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
import RealmSwift

enum AreaType: Int8 {
    case WildlifeProtectionArea = 1
    case SpecialProtectionArea = 2
    case GameReserve = 3
    case PaidGameHuntingArea = 8
    case CertainHuntingEquipmentProhibitedArea = 9
}

class RestrictedAreaModel {
    // http://nlftp.mlit.go.jp/ksj/jpgis/datalist/KsjTmplt-A15.html
    enum ShapeFiles: String {
        // Hokkaido
        case Hokkaido = "A15-09_01_WildlifePreserve"
        
        // Tohoku
        case Aomori = "A15-09_02_WildlifePreserve"
        case Iwate = "A15-09_03_WildlifePreserve"
        case Miyagi = "A15-09_04_WildlifePreserve"
        case Akita = "A15-09_05_WildlifePreserve"
        case Yamagata = "A15-09_06_WildlifePreserve"
        case Fukushima = "A15-09_07_WildlifePreserve"
        
        // Kanto
        case Ibaraki = "A15-09_08_WildlifePreserve"
        case Tochigi = "A15-09_09_WildlifePreserve"
        case Gumma = "A15-09_10_WildlifePreserve"
        case Saitama = "A15-09_11_WildlifePreserve"
        case Chiba = "A15-09_12_WildlifePreserve"
        case Tokyo = "A15-09_13_WildlifePreserve"
        case Kanagawa = "A15-09_14_WildlifePreserve"
        
        // Chubu
        case Nigata = "A15-09_15_WildlifePreserve"
        case Toyama = "A15-09_16_WildlifePreserve"
        case Ishikawa = "A15-09_17_WildlifePreserve"
        case Fukui = "A15-09_18_WildlifePreserve"
        case Yamanashi = "A15-09_19_WildlifePreserve"
        case Nagano = "A15-09_20_WildlifePreserve"
        case Gifu = "A15-09_21_WildlifePreserve"
        case Shizuoka = "A15-09_22_WildlifePreserve"
        case Aichi = "A15-09_23_WildlifePreserve"
        
        // Kinki
        case Mie = "A15-09_24_WildlifePreserve"
        case Shiga = "A15-09_25_WildlifePreserve"
        case Kyoto = "A15-09_26_WildlifePreserve"
        case Osaka = "A15-09_27_WildlifePreserve"
        case Hyogo = "A15-09_28_WildlifePreserve"
        case Nara = "A15-09_29_WildlifePreserve"
        case Wakayama = "A15-09_30_WildlifePreserve"
        
        // Chugoku
        case Tottori = "A15-09_31_WildlifePreserve"
        case Shimane = "A15-09_32_WildlifePreserve"
        case Okayama = "A15-09_33_WildlifePreserve"
        case Hiroshima = "A15-09_34_WildlifePreserve"
        case Yamaguchi = "A15-09_35_WildlifePreserve"
        
        // Shikoku
        case Tokushima = "A15-09_36_WildlifePreserve"
        case Kagawa = "A15-09_37_WildlifePreserve"
        case Ehime = "A15-09_38_WildlifePreserve"
        case Kochi = "A15-09_39_WildlifePreserve"
        
        // Kusyu
        case Fukuoka = "A15-09_40_WildlifePreserve"
        case Saga = "A15-09_41_WildlifePreserve"
        case Nagasaki = "A15-09_42_WildlifePreserve"
        case Kumamoto = "A15-09_43_WildlifePreserve"
        case Oita = "A15-09_44_WildlifePreserve"
        case Miyazaki = "A15-09_45_WildlifePreserve"
        case Kagoshima = "A15-09_46_WildlifePreserve"
        
        // Okinawa
        case Okinawa = "A15-09_47_WildlifePreserve"
        static let entries = [Hokkaido, Aomori, Iwate, Miyagi, Akita, Yamagata, Fukushima, Ibaraki, Tochigi, Gumma, Saitama, Chiba, Tokyo, Kanagawa, Nigata, Toyama, Ishikawa, Fukui, Yamanashi, Nagano, Gifu, Shizuoka, Aichi, Mie, Shiga, Kyoto, Osaka, Hyogo, Nara, Wakayama, Tottori, Shimane, Okayama, Hiroshima, Yamaguchi, Tokushima, Kagawa, Ehime, Kochi, Fukuoka, Saga, Nagasaki, Kumamoto, Oita, Miyazaki, Kagoshima, Okinawa]
    }
    
    // fieldNames defined in DBF
    enum FieldNames: String {
        case id = "A15_001"
        case prefCd = "A15_002"
        case institution = "A15_003"
        case areaType = "A15_004"
        case areaName = "A15_005"
        case listedDate = "A15_006"
        case delistedDate = "A15_007"
    }
    
    static func initDatabase() {
        let realm = try! Realm()
        if realm.objects(Area).count == 0 && realm.objects(Coordinate).count == 0 {
            print("initializing database")
            reload()
        }
    }
    
    static func reload() {
        for shapeFile in ShapeFiles.entries {
            loadFromSource(shapeFile.rawValue)
        }
    }
    
    static func selectAreasByRegion(region: MKCoordinateRegion) -> Results<Area> {
        let regionMaxLat = region.center.latitude + region.span.latitudeDelta / 2.0
        let regionMinLat = region.center.latitude - region.span.latitudeDelta / 2.0
        let regionMaxLng = region.center.longitude + region.span.longitudeDelta / 2.0
        let regionMinLng = region.center.longitude - region.span.longitudeDelta / 2.0
        
        let realm = try! Realm()
        let areas = realm.objects(Area)
            .filter("minLat < \(regionMaxLat) AND maxLat > \(regionMinLat) AND minLng < \(regionMaxLng) AND maxLng > \(regionMinLng)")
            .sorted("boundingRectDimension", ascending: false)
        return areas
    }
    
    static private func loadFromSource(resourceName: String) {
        let realm = try! Realm()
        
        func handler(args: ShapeFileHandlerArgs) -> Void {
            let area = Area()
            area.areaId = NSUUID().UUIDString
            area.areaName = getStringFieldValue(FieldNames.areaName.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.externalId = getStringFieldValue(FieldNames.id.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.prefCd = getStringFieldValue(FieldNames.prefCd.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.areaType.value = getInt8FieldValue(FieldNames.areaType.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.institution.value = getInt8FieldValue(FieldNames.institution.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.boundingRectDimension.value = args.boundingRectDimension
            area.maxLat.value = args.shpObject.dfYMax
            area.minLat.value = args.shpObject.dfYMin
            area.maxLng.value = args.shpObject.dfXMax
            area.minLng.value = args.shpObject.dfXMin
            area.listedDate = getDateFieldValue(FieldNames.listedDate.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            area.delistedDate = getDateFieldValue(FieldNames.delistedDate.rawValue, dbf: args.dbf, shpObject: args.shpObject)
            
            area.coordinates.appendContentsOf(args.coordinates.map {
                let coordinate = Coordinate()
                coordinate.area = area
                coordinate.latitude = $0.latitude
                coordinate.longitude = $0.longitude
                area.coordinates.append(coordinate)
                return coordinate
            })
            
            try! realm.write({
                realm.add(area)
            })
            
        }
        
        let path = ShapeFileUtil.getResourcePathForShapeLib(resourceName)
        ShapeFileUtil.loadShapeFile(path, withHandler: handler)
    }
    
    static private func getStringFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> String? {
        let fieldIndex = DBFGetFieldIndex(dbf, fieldName)
        return String.fromCString(DBFReadStringAttribute(dbf, shpObject.nShapeId, fieldIndex))
    }
    
    static private func getIntFieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> Int {
        return Int(DBFReadIntegerAttribute(dbf, shpObject.nShapeId, DBFGetFieldIndex(dbf, fieldName)))
    }
    
    static private func getInt8FieldValue(fieldName: String, dbf: DBFHandle, shpObject: SHPObject) -> Int8 {
        return Int8(DBFReadIntegerAttribute(dbf, shpObject.nShapeId, DBFGetFieldIndex(dbf, fieldName)))
    }
    
    static private func getDateFieldValue(fieldName: String,dbf: DBFHandle, shpObject: SHPObject) -> NSDate? {
        guard let fieldValue = getStringFieldValue(fieldName, dbf: dbf, shpObject: shpObject) else {
            return nil
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.dateFromString(fieldValue)
    }
}