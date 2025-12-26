//
//  Profile+CoreDataProperties.swift
//  Breatheful
//
//  Created by Handler on 7/13/24.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var afternoonReminder: Date?
    @NSManaged public var afternoonReminderEnabled: Bool
    @NSManaged public var dailyGoal: Int64
    @NSManaged public var dailyUsageMinutes: Data?
    @NSManaged public var morningReminder: Date?
    @NSManaged public var morningReminderEnabled: Bool
    @NSManaged public var name: String?
    @NSManaged public var nightReminder: Date?
    @NSManaged public var nightReminderEnabled: Bool
    @NSManaged public var preferredAudioMode: String?
    @NSManaged public var preferredBreathingMode: String?
    @NSManaged public var weeklyAverage: Int64
    @NSManaged public var selectedYear: Int64

}

extension Profile : Identifiable {

}
