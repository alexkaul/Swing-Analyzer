//
//  SensorData+CoreDataProperties.swift
//  
//
//  Created by Alexandra Kaulfuss on 20.11.16.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension SensorData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SensorData> {
        return NSFetchRequest<SensorData>(entityName: "SensorData");
    }

    @NSManaged public var loggingTime: NSDate?
    @NSManaged public var accelerationX: Double
    @NSManaged public var accelerationY: Double
    @NSManaged public var accelerationZ: Double
    @NSManaged public var rotationX: Double
    @NSManaged public var rotationY: Double
    @NSManaged public var rotationZ: Double
    @NSManaged public var motionPitch: Double
    @NSManaged public var motionRoll: Double
    @NSManaged public var motionYaw: Double
    @NSManaged public var cdSwing: CDSwing?

}
