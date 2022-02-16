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
    @Published var streak: Int = -1
    @Published var onboardingFinished: Bool = false
    @Published var betablockerOutcomes: Array<OCKAnyOutcome> = []
    @Published var feedback: String = ""
    var lastWarnDate: Date = Date().addingTimeInterval(-604800)
    var firstStreakAdded = false

    let notificationHandler = NotificationHandler()
    let eventStore = EKEventStore()
    let storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "com.apple.medrem.carekitstore", type: .onDisk(protection: .complete)))
    let listOfDates = [Date(), Date(timeInterval: 86400, since: Date()), Date(timeInterval: 86400*2, since: Date())]


    init() {
        self.triggerBoundary = UserDefaults.standard.object(forKey: "triggerBoundary") as? Double ?? 0.0
        self.dynamicBoundary = UserDefaults.standard.object(forKey: "dynamicBoundary") as? Bool ?? true
        self.warningDates = UserDefaults.standard.object(forKey: "warningDates") as? Array<Date> ?? []
        self.dynamicBoundaryGap = UserDefaults.standard.object(forKey: "dynamicBoundaryGap") as? Double ?? 3.0
        self.medicationTime = UserDefaults.standard.object(forKey: "medicationTime") as? String ?? ""
        self.streak = UserDefaults.standard.object(forKey: "streak") as? Int ?? 0
        self.firstStreakAdded = UserDefaults.standard.object(forKey: "firstStreakAdded") as? Bool ?? false
        self.onboardingFinished = UserDefaults.standard.object(forKey: "onboardingFinished") as? Bool ?? false
        self.betablockerOutcomes = UserDefaults.standard.object(forKey: "betablockerOutcomes") as? Array<OCKAnyOutcome> ?? []
        self.feedback = UserDefaults.standard.object(forKey: "feedback") as? String ?? ""
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

    func setFirstStreakAdded (added: Bool) {
        firstStreakAdded = added
        UserDefaults.standard.set(added, forKey: "firstStreakAdded")
    }

    func setOnboardingFinished () {
        onboardingFinished = true
        UserDefaults.standard.set(onboardingFinished, forKey: "onboardingFinished")
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

    func setStreak (streak: Int) {
        NSLog("Setting streak \(streak)")
        self.streak = streak
        UserDefaults.standard.set(streak, forKey: "streak")
    }

    func getStreak () -> Int {
        getBetablockerResults()
        return streak
    }

    func removeStreak () {
        NSLog("Removing streak")
        streak = -1
        setFirstStreakAdded(added: false)
        UserDefaults.standard.set(streak, forKey: "streak")
    }

    func getTriggerBoundary() -> Double {
        return triggerBoundary
    }

    func getOnboardingFinished () -> Bool {
        if (onboardingFinished) {
            return onboardingFinished
        }
        getOnboardingResults()
        return onboardingFinished
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
            self.notificationHandler.SendMedicationReminderNotification(title: "Medication time!", body: "It's time to take your medication", hour: hour, minute: minute)
        }
    }

    func setLastWarnDate(date: Date) {
        self.lastWarnDate = date
    }
    
    func setFeedback (feedback: String) {
        self.feedback = feedback
        UserDefaults.standard.set(feedback, forKey: "feedback")
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

        storeManager.store.fetchAnyOutcomes(query: query, callbackQueue: .main) { result in
               switch result {
               case .failure:
                   NSLog("Failed to fetch betablocker outcomes")
               case let .success(outcomes):
                   NSLog("BETABLOCKER: outcomes gotten \(outcomes)")
                   self.betablockerOutcomes = outcomes
                   self.countStreak(outcomes: outcomes)
                   self.setFeedback(feedback: self.getFeedback())
               }
        }
    }

    func countStreak (outcomes: [OCKAnyOutcome]) {
        let lastOutcome = outcomes.first as? OCKOutcome
        let lastOutcomeDate = lastOutcome?.createdDate ?? Date(timeIntervalSince1970: 0)
        NSLog("Lastoutcomedate = \(lastOutcomeDate)")
        
        var differenceInDays = Calendar.current.dateComponents([.day], from: lastOutcomeDate, to: Date())

        if (outcomes.count == 1 && differenceInDays.day == 0 ) {
            NSLog("Setting streak to 0 because its the first day of registered outcomes")
            setStreak(streak: 0)
            return
        }

        if (differenceInDays.day! > 1) {
            NSLog("Setting streak to 0 because of difference in days are bigger than 1")
            setStreak(streak: 0)
            return
        }


        var current = Calendar.current.startOfDay(for: lastOutcomeDate)
        var beforeCurrent = lastOutcome
        var beforeCurrentDate = lastOutcomeDate
        var streak = 0

        for index in stride(from: 1, to: outcomes.count, by: 1) {
            
            NSLog("Index: \(index)")
            beforeCurrent = outcomes[index] as? OCKOutcome
            beforeCurrentDate = Calendar.current.startOfDay(for: beforeCurrent?.createdDate ?? Date(timeIntervalSince1970: 0))
            NSLog("Current: \(current)")
            NSLog("Before: \(beforeCurrentDate)")

            differenceInDays = Calendar.current.dateComponents([.day], from: beforeCurrentDate , to: current)
            NSLog("Difference: \(differenceInDays)")

            if (differenceInDays.day == 1) {
                streak += 1
                current = beforeCurrentDate
                NSLog("Streak is currently \(streak)")
            } else {
                setStreak(streak: streak)
                return
            }
        }
        setStreak(streak: streak)
    }

    private func getOnboardingResults ()  {
        var query = OCKOutcomeQuery()
        query.taskIDs = ["onboarding"]

        storeManager.store.fetchAnyOutcomes(
            query: query,
            callbackQueue: .main) { result in
                switch result {
                case .failure:
                    print("Failed to fetch onboarding outcomes!")
                case .success(_):
                    NSLog("Onboarding successful")
                    self.setOnboardingFinished()
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
    
    func sundayChecker (date: Date) ->  Bool {
        let calendar: Calendar = Calendar.current
        NSLog("Date we are checking: \(date)")
        let isSunday = calendar.component(Calendar.Component.weekday, from: date) == 1
        NSLog("\(calendar.component(Calendar.Component.weekday, from: date))")
        return isSunday
    }
    
    func getFeedback () -> String {
        let feedback = checkWhichFeedback()
        switch feedback {
        case .perfect:
            return "Well done! You have taken your medication every day this week 👏"
        case .good:
            return "This week you remembered your medication for the most part. Keep going, you'll make it to 7/7 next week!"
        case .average:
            return "This week you only remembered your medication half of the time, work better to remember your medication next week!"
        case .bad:
            return "This was not a good week, to improve the effect of your medication take your medication everyday next week! You can do it!"
        case .horrible:
            return "You haven't taken your medicine all week, try to put the medication somewhere you can see them so that you take them next week as well!"
        case .error:
            return "An error has occured"
        }
    }
    
    func checkWhichFeedback () -> Feedback {
        switch numberOfMedicatedDaysThisWeek() {
        case 0:
            return .horrible
        case 1...2:
            return .bad
        case 3...4:
            return .average
        case 5...6:
            return .good
        case 7:
            return .perfect
        default:
            return .error
        }
    }
    
    func numberOfMedicatedDaysThisWeek () -> Int {
        var numberOfDays = 0
        NSLog("FEEDBACK: Outcomes in counting: \(self.betablockerOutcomes)")
        
        
        for outcome in self.betablockerOutcomes {
            let ockOutcome = outcome as? OCKOutcome
            let outcomeDate = ockOutcome?.createdDate ?? Date(timeIntervalSince1970: 0)
    
            if(dateWithinWeek(date: outcomeDate)) {
                numberOfDays += 1
            } else {
                NSLog("FEEDBACK: returning \(numberOfDays)")
                return numberOfDays
            }
        }
        NSLog("FEEDBACK: returning \(numberOfDays)")
        return numberOfDays
    }
    
    func dateWithinWeek (date: Date) -> Bool {
        let currentComponents = Calendar.current.dateComponents([.weekOfYear], from: Date())
        let dateComponents = Calendar.current.dateComponents([.weekOfYear], from: date)
        guard let currentWeekOfYear = currentComponents.weekOfYear, let dateWeekOfYear = dateComponents.weekOfYear else { return false }
        
        return currentWeekOfYear == dateWeekOfYear
    }
}


enum Feedback {
    case perfect, good, average, bad, horrible, error
}
