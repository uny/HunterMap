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


class ShapeFileUtil {
    
    // remove extention from resource
    static func getResourcePathForShapeLib(resourceName: String) -> String {
        let shpFilePath = NSBundle.mainBundle().pathForResource(resourceName, ofType: "shp")
        return (shpFilePath! as NSString).stringByAppendingPathComponent("")
    }
    
    // load shape file with handler method
    static func loadShapeFile(path: String, handler: ((coordinates: [CLLocationCoordinate2D], shpObject: SHPObject, dbf: DBFHandle)->Void)?) {
        // open dbf, shp
        let dbf = DBFOpen(path, "rb")
        let shp = SHPOpen(path, "rb")
        var pnEntities: Int32 = 0
        SHPGetInfo(shp, &pnEntities, nil, nil, nil)
        
        // extract all SHPObjects
        for i in 0..<pnEntities {
            let shpObjectPointer = SHPReadObject(shp, i)
            let shpObject = shpObjectPointer.memory
            
            let numParts = Int(shpObject.nParts)
            let totalVertexCount = Int(shpObject.nVertices)
            
            // extract all Vertices
            for j in 0..<numParts {
                let startVertex = Int(shpObject.panPartStart[j])
                let partVertexCount = (j == numParts-1) ? totalVertexCount - startVertex : Int(shpObject.panPartStart[j+1]) - startVertex
                let endIndex = startVertex + partVertexCount
                var coordinates = [CLLocationCoordinate2D]()
                for k in startVertex..<endIndex {
                    let coord = CLLocationCoordinate2DMake(shpObject.padfY[k], shpObject.padfX[k])
                    coordinates.append(coord)
                }
                
                handler?(coordinates: coordinates, shpObject: shpObject, dbf: dbf)
            }
            SHPDestroyObject(shpObjectPointer)
        }
        
        // close dbf, shp
        SHPClose(shp)
        DBFClose(dbf)
    }
}