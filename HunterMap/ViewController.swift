//
//  ViewController.swift
//  HunterMap
//
//  Created by 佐橘　一旗 on 5/7/16.
//  Copyright © 2016 1tsuki. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import shapelib

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    /**
     * viewDidLoad
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        self.locationManager.requestWhenInUseAuthorization()
        
        self.locationManager.startUpdatingLocation()
        
        self.mapView.delegate = self
        
        self.mapView.showsUserLocation = true
    }
    
    /**
     * viewDidAppear
     * 
     * Load and draw shapeFile after the map has initialized
     * dataSource : http://nlftp.mlit.go.jp/ksj/jpgis/datalist/KsjTmplt-A15.html
     */
    override func viewDidAppear(animated: Bool) {
        let shpFilePath = NSBundle.mainBundle().pathForResource("A15-09_14_WildlifePreserve", ofType: "shp")
        
        // remove extension from shpFilePath
        let path = (shpFilePath! as NSString).stringByAppendingPathComponent("")
        loadShapeFile(path)
    }
    
    /**
     * didReceiveMemoryWarning
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Location Delegate Methods
    /**
     * show current location on map
     */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last!
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let region = MKCoordinateRegion(center : center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        
        self.mapView.setRegion(region, animated: true)
    }
    
    /**
     * didFailWithError
     */
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    // MARK: - ShapeLib
    /**
     * load shape file and draw area on map
     */
    func loadShapeFile(path: String) {
        let dbf = DBFOpen(path, "rb")
        let typeIndex = DBFGetFieldIndex(dbf, "A15_004")
        
        let shp = SHPOpen(path, "rb")
        
        var pnEntities: Int32 = 0
        var pnShapeType: Int32 = 0
        SHPGetInfo(shp, &pnEntities, &pnShapeType, nil, nil)
        
        // loop all SHPObjects
        for i in 0..<pnEntities {
            let shpObject = SHPReadObject(shp, i).memory
            
            let type = DBFReadIntegerAttribute(dbf, shpObject.nShapeId, typeIndex)
            
            let numParts = Int(shpObject.nParts)
            let totalVertexCount = Int(shpObject.nVertices)
            
            // loop all Vertices
            for j in 0..<numParts {
                let startVertex = Int(shpObject.panPartStart[j])
                let partVertexCount = (j == numParts-1) ? totalVertexCount - startVertex : Int(shpObject.panPartStart[j+1]) - startVertex
                let endIndex = startVertex + partVertexCount
                
                var coordinates: [CLLocationCoordinate2D] = []
                // vertexes
                for k in startVertex..<endIndex {
                    let coord = CLLocationCoordinate2DMake(shpObject.padfY[k], shpObject.padfX[k])
                    coordinates.append(coord)
                }
                switch type {
                case 1:
                    let polygon = HMGameReserveOverlay(coordinates: &coordinates, count: coordinates.count)
                    mapView.addOverlay(polygon)
                case 2:
                    let polygon = HMSpecialProtectionAreaOverlay(coordinates: &coordinates, count: coordinates.count)
                    mapView.addOverlay(polygon)
                case 3:
                    let polygon = HMTempGameReserveOverlay(coordinates: &coordinates, count: coordinates.count)
                    mapView.addOverlay(polygon)
                default:
                    break
                }
            }
        }
        SHPClose(shp)
        
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polygonView = MKPolygonRenderer(overlay: overlay)
        if overlay is HMGameReserveOverlay {
            polygonView.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.magentaColor().colorWithAlphaComponent(0.7)
        } else if overlay is HMSpecialProtectionAreaOverlay {
            polygonView.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.cyanColor().colorWithAlphaComponent(0.7)
        } else if overlay is HMTempGameReserveOverlay {
            polygonView.strokeColor = UIColor.yellowColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.7)
        } else {
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        }
        
        polygonView.lineWidth = 3
        
        return polygonView
    }
    
}

