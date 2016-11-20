//
//  CDSwing+CoreDataProperties.swift
//  
//
//  Created by Alexandra Kaulfuss on 20.11.16.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDSwing {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSwing> {
        return NSFetchRequest<CDSwing>(entityName: "CDSwing");
    }

    @NSManaged public var recordingTime: Date
    @NSManaged public var sensorData: SensorData?

}

extension CDSwing {
    
    @objc(addSensorDataObject:)
    @NSManaged public func addToSensorData(_ value: SensorData)
    
    @objc(removeSensorDataObject:)
    @NSManaged public func removeFromSensorData(_ value: SensorData)
    
    @objc(addSensorData:)
    @NSManaged public func addToSensorData(_ values: NSSet)
    
    @objc(removeSensorData:)
    @NSManaged public func removeFromSensorData(_ values: NSSet)
    
}
