//
//  HunterMapViewController.swift
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
    
    @IBOutlet weak var mapOptions: UISegmentedControl!
    
    @IBOutlet weak var locationTrackingButton: UIButton!
    
    @IBOutlet weak var createLogButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    enum MapType: Int {
        case Standard = 0
        case Hybrid
        case Satellite
    }
    
    // MARK: - ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // location manager
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        // mapView
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.locationTrackingButton.enabled = false
    }
    
    
    
    // MARK: - MapView Delegate Methods
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.renderRestrictedAreas()
    }
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if mapViewRegionDidChangeFromUserInteraction() {
            self.setLocationTrackingEnabled(false)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polygonView = MKPolygonRenderer(overlay: overlay)
        polygonView.lineWidth = 3
        
        switch overlay {
        case is HMWildlifeProtectionAreaOverlay:
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.magentaColor().colorWithAlphaComponent(0.7)
        case is HMSpecialProtectionAreaOverlay:
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.redColor().colorWithAlphaComponent(0.7)
        case is HMGameReserveOverlay:
            polygonView.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            polygonView.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        default:
            break
        }
        return polygonView
    }
    
    // MARK: - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        
        if isLocationTrackingEnabled() {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center : center, span: self.mapView.region.span)
            self.mapView.setRegion(region, animated: true)
        }
    }
    

    // MARK: - user interactions
    @IBAction func mapTypeChanged(sender: AnyObject) {
        let mapType = MapType(rawValue: self.mapOptions.selectedSegmentIndex)
        switch mapType! {
        case .Standard:
            self.mapView.mapType = MKMapType.Standard
        case .Hybrid:
            self.mapView.mapType = MKMapType.Hybrid
        case .Satellite:
            self.mapView.mapType = MKMapType.Satellite
        }
    }
    
    @IBAction func enableLocationTracking(sender: AnyObject) {
        self.setLocationTrackingEnabled(true)
        let latitudeDelta = min(self.mapView.region.span.latitudeDelta, 0.1)
        let longitudeDelta = min(self.mapView.region.span.longitudeDelta, 0.1)
        self.mapView.region.span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
    }
    
    @IBAction func createLog(sender: AnyObject) {
        print("pressed")
    }
    
    // MARK: - error handlings
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    // MARK: - private methods
    private func renderRestrictedAreas() {
        let restrictedAreaOverlays = self.mapView.overlays.filter({$0 is HMRestrictedAreaOverlay})
        self.mapView.removeOverlays(restrictedAreaOverlays)
        
        let restrictedAreas = RestrictedAreaModel.selectAreasByRegion(self.mapView.region)
        for i in 0..<min(restrictedAreas.count, 30) {
            let area = restrictedAreas[i]
            guard area.areaType.value != nil else {
                continue
            }
            
            var coordinates = area.coordinates.map { $0.getCLLocationCoordinate2D() }
            switch area.areaType.value! {
            case AreaType.WildlifeProtectionArea.rawValue:
                let polygon = HMWildlifeProtectionAreaOverlay(coordinates: &coordinates, count: coordinates.count)
                self.mapView.addOverlay(polygon)
            case AreaType.SpecialProtectionArea.rawValue:
                let polygon = HMSpecialProtectionAreaOverlay(coordinates: &coordinates, count: coordinates.count)
                self.mapView.addOverlay(polygon)
            case AreaType.GameReserve.rawValue:
                let polygon = HMGameReserveOverlay(coordinates: &coordinates, count: coordinates.count)
                self.mapView.addOverlay(polygon)
            default:
                break
            }
        }
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.Began
                    || recognizer.state == UIGestureRecognizerState.Ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    private func setLocationTrackingEnabled(status: Bool) {
        self.locationTrackingButton.enabled = !status
    }
    
    private func isLocationTrackingEnabled() -> Bool {
        return !self.locationTrackingButton.enabled
    }
    
}