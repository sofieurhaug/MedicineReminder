//
//  UserDataa.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 19/01/2022.
//

import SwiftUI
import EventKit
import CareKit
import CareKitStore

class UserData: ObservableObject {
    @Published var lastRestingHeartRate: Double = 0.0
    @Published var restingHeartRates: Array<Double> = []
    @Published var triggerBoundary: Double = 0.0
    @Published var dates: Array<Date> = []
    @Published var dynamicBoundary: Bool = true
    @Published var dynamicBoundaryGap: Double = 3.0
    @Published var warningDates: Array<Date> = []
    @Published var notifyQuestion: Bool = false
    @Published var remindQuestion: Bool = false
    @Published var medicationTime: String = ""
    @Published var streak: Int = 0
    var lastBetablockerCompletion: Date = Date(timeIntervalSince1970: 0)
    var lastWarnDate: Date = Date().addingTimeInterval(-604800)
    var firstStreakRegistered: Bool = false

    let notificationHandler = NotificationHandler()
    let eventStore = EKEventStore()
    let storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "com.apple.medrem.carekitstore", type: .inMemory))
    


    init() {
        self.triggerBoundary = UserDefaults.standard.object(forKey: "triggerBoundary") as? Double ?? 0.0
        self.dynamicBoundary = UserDefaults.standard.object(forKey: "dynamicBoundary") as? Bool ?? true
        self.warningDates = UserDefaults.standard.object(forKey: "warningDates") as? Array<Date> ?? []
        self.dynamicBoundaryGap = UserDefaults.standard.object(forKey: "dynamicBoundaryGap") as? Double ?? 3.0
        self.medicationTime = UserDefaults.standard.object(forKey: "medicationTime") as? String ?? ""
        self.streak = UserDefaults.standard.object(forKey: "streak") as? Int ?? 0
    }

    func setLastRestingHR(heartRate: Double) {
        lastRestingHeartRate = heartRate
    }

    func setTriggerBoundary(boundary: Double) {
        triggerBoundary = boundary
        UserDefaults.standard.set(triggerBoundary, forKey: "triggerBoundary")
    }

    func setDynamicBoundaryGap(gap: Double) {
        dynamicBoundaryGap = gap
        UserDefaults.standard.set(dynamicBoundaryGap, forKey: "dynamicBoundaryGap")
    }

    func setDynamicBoundary(bool: Bool) {
        dynamicBoundary = bool
        UserDefaults.standard.set(dynamicBoundary, forKey: "dynamicBoundary")
    }

    func setMedicationTime(time: String) {
        self.medicationTime = time
        UserDefaults.standard.set(medicationTime, forKey: "medicationTime")
        setMedicationTimeNotification(time: time)
    }
    
    func setLastBetablockerCompletion (date: Date) {
        lastBetablockerCompletion = date
    }

    func changeNotifyQuestion(bool: Bool) {
        notifyQuestion = bool
        NSLog("Changed notifyQuestion to: \(notifyQuestion)")
    }

    func changeRemindQuestion(bool: Bool) {
        remindQuestion = bool
        NSLog("Changed notifyQuestion to: \(remindQuestion)")
    }

    func getDynamicBoundaryGap() -> Double {
        return dynamicBoundaryGap
    }


    func addStreak () {
        NSLog("Adding Streak")
        streak += 1
    }

    func removeStreak () {
        NSLog("Removing streak")
        streak = 0
    }

    func getTriggerBoundary() -> Double {
        return triggerBoundary
    }


    func setRestingHRs(heartRates: Array<Double>, dates: Array<Date>) {
        NSLog("Setting resting heart rates")
        DispatchQueue.main.async {
            self.restingHeartRates = heartRates
            self.dates = dates

            //Check for initial resting heart rate
            if self.lastRestingHeartRate == 0.0 {
                self.setLastRestingHR(heartRate: self.restingHeartRates[self.restingHeartRates.count - 1])
                NSLog("Initial resting heart rate: \(self.lastRestingHeartRate)")
                return
            }
            //Check for new resting Heart Rate
            if self.isHRCurrent() && self.lastRestingHeartRate != heartRates[heartRates.count - 1]{
                self.setLastRestingHR(heartRate: heartRates[heartRates.count - 1])
            }
            NSLog("Checking notification trigger")
            //Check notification trigger
            if self.isHRCurrent() && self.lastRestingHeartRate > self.triggerBoundary && self.timeChecker() && self.triggerBoundary > 20.0 {
                NSLog("Passed trigger")
                if self.lastWarnDate.addingTimeInterval(600) < Date() {
                    NSLog("Passed Date check")
                    self.changeNotifyQuestion(bool: true)
                    self.lastWarnDate = Date()
                    self.notificationHandler.SendActionNotification(title: "Beta-blocker warning!", body: "Your resting heart rate value is: \(self.lastRestingHeartRate). This is above your set boundary: \(self.triggerBoundary). Have you remembered your medication today?", timeInterval: 1)
                    NSLog("Sent notification")

                } else {
                    NSLog("Failed Date trigger")
                    print(self.lastWarnDate.addingTimeInterval(600))
                }
            }
        }
    }

    func setMedicationTimeNotification (time: String) {
        let hour = Int(time.split(separator: "-")[0]) ?? -1
        let minute = Int(time.split(separator: "-")[1]) ?? -1

        NSLog("Checking medication time for notitication ")
        if (hour < 0 || minute < 0) {
            NSLog("Error: Hour or minute was negative")
            return
        }

        DispatchQueue.main.async {
            NSLog("Passed medication time check")
            self.notificationHandler.SendMedicationReminderNotification(title: "Medication time!", body: "It's time to take your medication", hour: hour, minute: hour)
        }
    }

    func setLastWarnDate(date: Date) {
        if (date != self.lastBetablockerCompletion) {
            
        }
        self.lastWarnDate = date
        
    }

    func setLostStreakNotification () {

    }

    func increaseBoundary() {
        NSLog("Increasing boundary by \(self.dynamicBoundaryGap)")
        let newValue = self.triggerBoundary + self.dynamicBoundaryGap
        setTriggerBoundary(boundary: newValue)
    }

    func logCorrectWarning(date: Date) {
        NSLog("Logging date of correct warning")
        warningDates.append(date)
        UserDefaults.standard.set(warningDates, forKey: "warningDates")
    }

    // MARK: - Extras

    func getCurrentHR(rHR: Double) -> String {
        if isHRCurrent() {
                return String(rHR)
            }
        return "--"
    }

    func isHRCurrent() -> Bool {
        if self.dates != [] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EE"

            let lastDate = dateFormatter.string(from: self.dates[self.dates.count - 1])
            let currentDate = dateFormatter.string(from: Date())

            if lastDate == currentDate {
                return true
            }
        }
        return false
    }
    
    func getBetablockerResults () {
        var query = OCKOutcomeQuery()
        query.taskIDs = ["betablocker"]
        
        storeManager.store.fetchAnyOutcomes(
            query: query,
            callbackQueue: .main) { result in
                switch result {
                case .failure:
                    NSLog("Failed to fetch betablocker outcomes")
                case let .success(outcomes):
                    let lastOutcome = outcomes.last as? OCKOutcome
                    NSLog("\(lastOutcome)")
                    let lastOutcomeDate = lastOutcome?.createdDate ?? Date(timeIntervalSince1970: 0)
                    if (lastOutcomeDate != Date(timeIntervalSince1970: 0)) {
                        //TODO: Gjør noe med streak siden datoen er ny
                        //sjekk om den nye dataen er fra tidligere enn i går
                        let differenceInDays = Calendar.current.dateComponents([.day], from: self.lastBetablockerCompletion, to: lastOutcomeDate)
                        
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(timeIntervalSince1970: 0)
                        NSLog("Yesterday: \(yesterday)")
                        //let differenceInDays =  Calendar.current.dateComponents([.day], from: yesterday, to: lastOutcomeDate)
                        NSLog("difference between today and yesterday: \(differenceInDays)")
                        switch differenceInDays.day {
                        case 0:
                            return
                        case 1:
                            self.addStreak()
                        case 19013:
                            if(!self.firstStreakRegistered) {
                                self.firstStreakRegistered = true
                                self.addStreak()
                            }
                        default:
                            self.removeStreak()
                        }
                        
                  
                    }
                }
            }
    }

    private func timeChecker() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(
            bySettingHour: 14,
            minute: 0,
            second: 0,
            of: now)!

        let endTime = calendar.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: now)!

        if now >= startTime &&
            now <= endTime
        {
            return true
        }
        return false
    }
}
