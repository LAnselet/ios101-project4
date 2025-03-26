//
//  TriviaQuestionService.swift
//  Trivia
//
//  Created by syc on 2025/3/25.
//

import Foundation

struct TriviaAPIResponse: Decodable {
    let results: [TriviaQuestion]
}

class TriviaQuestionService {
    static func fetchTriviaQuestion(amount: Int, completion: (([TriviaQuestion]) -> Void)? = nil) {
        guard amount > 1 && amount <= 10 else {
            assertionFailure("Invalid amount")
            return
        }
        let url = URL(string: "https://opentdb.com/api.php?amount=\(amount)")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                assertionFailure("Error: \(error!.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                assertionFailure("Invalid response")
                return
            }
            guard let data = data, httpResponse.statusCode == 200 else {
                assertionFailure("Invalid response status code: \(httpResponse.statusCode)")
                return
            }
            // at this point, `data` contains the data received from the response
            let question = parse(data: data)
            let decoder = JSONDecoder()
            let response = try! decoder.decode(TriviaAPIResponse.self, from: data)
            // this response will be used to change the UI, so it must happen on the main thread
            DispatchQueue.main.async {
                completion?(response.results)
            }
        }
        task.resume()
    }
    private static func parse(data: Data) -> [TriviaQuestion] {
        // transform the data we received into a dictionary [String: Any]
        let jsonDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let triviaQuestion = jsonDictionary["results"] as! [[String: Any]]
        var triviaQuestions: [TriviaQuestion] = []
        for item in triviaQuestion {
            let category = item["category"] as! String
            let question = item["question"] as! String
            let correctAnswer = item["correct_answer"] as! String
            let incorrectAnswers = item["incorrect_answers"] as! [String]
            let triviaQuestion = TriviaQuestion(category: category, question: question, correctAnswer: correctAnswer, incorrectAnswers: incorrectAnswers)
            triviaQuestions.append(triviaQuestion)
        }
        return triviaQuestions
    }
}
