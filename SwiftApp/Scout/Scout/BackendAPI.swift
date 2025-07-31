//
//  BackendAPI.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/31/25.
//


import Foundation


private struct CheckoutSessionResponse: Decodable {
  let url: URL
}

enum APIError: Error {
  case network(Error)
  case server(String)
}

class BackendAPI {
  static let baseURL = URL(string: "http://localhost:4242")!

  static func createCheckoutSession(
    agent: Agent,
    userId: String,
    completion: @escaping (Result<URL, APIError>) -> Void
  ) {
    let url = baseURL.appendingPathComponent("create-checkout-session")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body = ["agentId": agent.apiID, "userId": userId]
    do {
      req.httpBody = try JSONEncoder().encode(body)
    } catch {
      return completion(.failure(.server("Encoding error")))
    }
     

    URLSession.shared.dataTask(with: req) { data, _, err in
      if let err = err {
        
        return completion(.failure(.network(err)))
      }
       
        
   
      guard let data = data,
            let resp = try? JSONDecoder().decode(CheckoutSessionResponse.self, from: data)
      else {
        return completion(.failure(.server("Invalid response")))
      }
       
      completion(.success(resp.url))
    }
    .resume()
  }
}
