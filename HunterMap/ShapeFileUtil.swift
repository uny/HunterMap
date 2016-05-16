//
//  ShapeFileUtil.swift
//  HunterMap
//
//  Created by 佐橘　一旗 on 5/8/16.
//  Copyright © 2016 1tsuki. All rights reserved.
//

import Foundation
import MapKit
import shapelib

struct ShapeFileHandlerArgs {
    let coordinates: [CLLocationCoordinate2D]
    let boundingRectDimension: Double
    let shpObject: SHPObject
    let dbf: DBFHandle
}

class ShapeFileUtil {
    
    static let kShapeFileExtension = "shp"
    
    /**
     remove extention from resource
     make sure that shape files are already added as resource
     */
    static func getResourcePathForShapeLib(resourceName: String) -> String {
        let shpFilePath = NSBundle.mainBundle().pathForResource(resourceName, ofType: kShapeFileExtension)
        return (shpFilePath! as NSString).stringByAppendingPathComponent("")
    }
    
    /**
     load shape file with result handler
     arg "path" should not contain extension, use getResourcePathForShapeLib for it
     */
    static func loadShapeFile(path: String, withHandler: ((args: ShapeFileHandlerArgs)->Void)?) {
        // open dbf
        let dbf = DBFOpen(path, "rb")
        defer { DBFClose(dbf) }
        
        // open shp
        let shp = SHPOpen(path, "rb")
        defer { SHPClose(shp) }
        
        // extract all SHPObjects
        var pnEntities: Int32 = 0
        SHPGetInfo(shp, &pnEntities, nil, nil, nil)
        for i in 0..<pnEntities {
            // read SHPObject
            let shpObjectPointer = SHPReadObject(shp, i)
            defer { SHPDestroyObject(shpObjectPointer) }
            let shpObject = shpObjectPointer.memory
            
            // SHPOBject contains several parts
            let numParts = Int(shpObject.nParts)
            let totalVertexCount = Int(shpObject.nVertices)
            for j in 0..<numParts {
                // extract vertices belonging to part
                let startVertex = Int(shpObject.panPartStart[j])
                let endIndex = (j == numParts-1) ? totalVertexCount : Int(shpObject.panPartStart[j+1])
                var coordinates = [CLLocationCoordinate2D]()
                for k in startVertex..<endIndex {
                    let coord = CLLocationCoordinate2DMake(shpObject.padfY[k], shpObject.padfX[k])
                    coordinates.append(coord)
                }
                
                // handle entity
                withHandler?(args: ShapeFileHandlerArgs(
                    coordinates: coordinates,
                    boundingRectDimension: getBoundingRectDimention(shpObject),
                    shpObject: shpObject,
                    dbf: dbf))
            }
        }
    }
    
    /**
     Calculate dimension of bounding rect
     */
    private static func getBoundingRectDimention(shpObject: SHPObject) -> Double {
        return fabs(shpObject.dfXMax - shpObject.dfXMin) * fabs(shpObject.dfYMax - shpObject.dfYMin)
    }
}