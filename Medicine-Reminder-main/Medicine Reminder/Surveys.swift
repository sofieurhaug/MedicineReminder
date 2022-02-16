//
//  Surveys.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 22/12/2021.
//
import Foundation
import CareKitStore
import ResearchKit

struct Surveys {

    private init() {}

    // MARK: Onboarding
    static func onboardingSurvey() -> ORKTask {
        
        // The Welcome Instruction step.
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "onboarding.welcome"
        )

        welcomeInstructionStep.title = "Welcome!👋"
        welcomeInstructionStep.detailText = "Thank you for joining this study. Tap Next to learn more before signing up."
        
        
        
        // The Informed Consent Instruction step.
        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "onboarding.overview"
        )

        studyOverviewInstructionStep.title = "Before You Join"
        studyOverviewInstructionStep.iconImage = UIImage(systemName: "checkmark.seal.fill")
        
        let heartBodyItem = ORKBodyItem(
            text: "The study will ask you to share some of your health data.",
            detailText: nil,
            image: UIImage(systemName: "heart.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let completeTasksBodyItem = ORKBodyItem(
            text: "During the study we will be tracking if you take your betablocker medication regularly.",
            detailText: nil,
            image: UIImage(systemName: "checkmark.circle.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        
        let streakLevelBodyItem = ORKBodyItem(text: "You will gain streak and increase your level if you take your medication every single day. For us to keep track of your streak you have open the app and register that you have taken your medication that day.", detailText: nil, image: UIImage(systemName: "flame.fill"), learnMoreItem: nil, bodyItemStyle: .image)
        
        let notificationBodyItem = ORKBodyItem(text: "To help you remember your medication we will set a notification to appear at a time that you choose.", detailText: nil, image: UIImage(systemName: "alarm.fill"), learnMoreItem: nil, bodyItemStyle: .image)

        let secureDataBodyItem = ORKBodyItem(
            text: "Your data is kept private and secure.",
            detailText: nil,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        
        studyOverviewInstructionStep.bodyItems = [
            heartBodyItem,
            completeTasksBodyItem,
            streakLevelBodyItem,
            notificationBodyItem,
            secureDataBodyItem
        ]

        
        // The Request Permissions step.

        let healthKitTypesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]

        let healthKitPermissionType =  ORKHealthKitPermissionType(
            sampleTypesToWrite: nil, objectTypesToRead: healthKitTypesToRead
        )

        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .badge, .sound]
        )

        let requestPermissionsStep = ORKRequestPermissionsStep(
            identifier: "onboarding.requestPermissionsStep",
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType
            ]
        )

        requestPermissionsStep.title = "Health Data Request"
        requestPermissionsStep.text = "Please review the health data types below and enable sharing to contribute to the study."
        
        let boundaryHRAnswerStyle = ORKNumericAnswerStyle(rawValue: 1)
        let boundaryHRFormat: ORKNumericAnswerFormat = ORKNumericAnswerFormat(style: boundaryHRAnswerStyle!, unit: "bpm", minimum: 0, maximum: 200)
        let boundaryHRStep = ORKQuestionStep(identifier: "onboarding.boundaryHRStep", title: "Boundary Heart Rate", question: "What is your boundary heart rate?", answer: boundaryHRFormat)
        boundaryHRStep.isOptional = false
        
        let medicationTimeAnswerFormat = ORKTimeOfDayAnswerFormat()
        let medictationTimeStep = ORKQuestionStep(identifier: "onboarding.medicationTimeStep", title: "Time of medication", question: "At what time do you take your beta-blocker medication?", answer: medicationTimeAnswerFormat)
        medictationTimeStep.isOptional = false
        
        // Completion Step
        let completionStep = ORKCompletionStep(
            identifier: "onboarding.completionStep"
        )

        completionStep.title = "Enrollment Complete"
        completionStep.text = "Thank you for enrolling in this study. Your participation will contribute to meaningful research!"

        let surveyTask = ORKOrderedTask(
            identifier: "onboarding",
            steps: [
                welcomeInstructionStep,
                studyOverviewInstructionStep,
                requestPermissionsStep,
                boundaryHRStep,
                medictationTimeStep,
                completionStep
            ]
        )

        return surveyTask
    }
}
