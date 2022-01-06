//
//  ResultParser.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 05/01/2022.
//

import Foundation
import ResearchKit

struct ResultParser {
    
//    static func getOnBoardingFiles(result: ORKTaskResult) -> [NSURL] {
//
//        var urls = [NSURL]()
//
//        guard let results = result.results else {
//            return urls
//        }
//
//        if (results.count > 4) {
//            let boundaryHRResult = results[3] as? ORKQuestionResult
//            let medicationTimeResult = results[4] as? ORKQuestionResult
//
//            let answer = boundaryHRResult?.answer
//
//            for result in boundaryHRResult.results! {
//              if let result = result as? ORKFileResult,
//                let fileUrl = result.fileURL {
//                  urls.append(fileUrl)
//              }
//            }
//
//            for result in medicationTimeResult.results! {
//              if let result = result as? ORKFileResult,
//                let fileUrl = result.fileURL {
//                urls.append(fileUrl)
//              }
//            }
//        }
//
//        return urls
//    }
}
