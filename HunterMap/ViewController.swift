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
        
        let region = MKCoordinateRegion(center : center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
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
        let shapeHandle = SHPOpen(path, "rb")
        
        var pnEntities: Int32 = 0
        var pnShapeType: Int32 = 0
        SHPGetInfo(shapeHandle, &pnEntities, &pnShapeType, nil, nil)
        
        // loop all SHPObjects
        for i in 0..<pnEntities {
            let shape = SHPReadObject(shapeHandle, i).memory
            
            shape.nSHPType
            
            let numParts = Int(shape.nParts)
            let totalVertexCount = Int(shape.nVertices)
            
            // loop all Vertexes
            for j in 0..<numParts {
                let startVertex = Int(shape.panPartStart[j])
                let partVertexCount = (j == numParts-1) ? totalVertexCount - startVertex : Int(shape.panPartStart[j+1]) - startVertex
                let endIndex = startVertex + partVertexCount
                
                var coordinates: [CLLocationCoordinate2D] = []
                // vertexes
                for k in startVertex...endIndex {
                    let coord = CLLocationCoordinate2DMake(shape.padfY[k], shape.padfX[k])
                    coordinates.append(coord)
                }
                let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
                mapView.addOverlay(polygon)
            }
        }
        
        SHPClose(shapeHandle)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polygonView = MKPolygonRenderer(overlay: overlay)
        polygonView.strokeColor = UIColor.magentaColor()
        
        return polygonView
    }
    
}

