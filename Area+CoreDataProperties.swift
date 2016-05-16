//
//  Area+CoreDataProperties.swift
//  
//
//  Created by 佐橘　一旗 on 5/14/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Area {

    @NSManaged var areaId: String?
    @NSManaged var areaName: String?
    @NSManaged var areaType: NSNumber?
    @NSManaged var delistedDate: NSDate?
    @NSManaged var institution: NSNumber?
    @NSManaged var listedDate: NSDate?
    @NSManaged var maxLat: NSNumber?
    @NSManaged var maxLng: NSNumber?
    @NSManaged var minLat: NSNumber?
    @NSManaged var minLng: NSNumber?
    @NSManaged var pref: NSNumber?
    @NSManaged var boundingRectDimension: NSNumber?
    @NSManaged var toMany: Coordinate?

}
