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
        renderRestrictedAreas()
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
    func renderRestrictedAreas() {
        let restrictedAreas = RestrictedAreaModel.loadRestrictedAreas(ShapeFiles.Kanagawa)
        
        for var area in restrictedAreas {
            switch area.areaType {
            case AreaType.WildlifeProtectionArea.rawValue:
                let polygon = HMWildlifeProtectionAreaOverlay(coordinates: &area.coordinates, count: area.coordinates.count)
                self.mapView.addOverlay(polygon)
            case AreaType.SpecialProtectionArea.rawValue:
                let polygon = HMSpecialProtectionAreaOverlay(coordinates: &area.coordinates, count: area.coordinates.count)
                self.mapView.addOverlay(polygon)
            case AreaType.GameReserve.rawValue:
                let polygon = HMGameReserveOverlay(coordinates: &area.coordinates, count: area.coordinates.count)
                self.mapView.addOverlay(polygon)
            default:
                let polygon = MKPolygon(coordinates: &area.coordinates, count: area.coordinates.count)
                self.mapView.addOverlay(polygon)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polygonView = MKPolygonRenderer(overlay: overlay)
        polygonView.lineWidth = 3
        
        if overlay is HMWildlifeProtectionAreaOverlay {
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.magentaColor().colorWithAlphaComponent(0.7)
        } else if overlay is HMSpecialProtectionAreaOverlay {
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.redColor().colorWithAlphaComponent(0.7)
        } else if overlay is HMGameReserveOverlay {
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        } else {
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        }
        
        return polygonView
    }
    
}

