//
//  GithubService.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation

class GithubService {
    public static let shared = GithubService()
    
    func search(_ q: String, completion: @escaping (Result<GithubSerachResponseModel, NetworkError>) -> Void) {
        let request = GithubSerachRequestModel(query: q)
        NetworkManager.shared.send(request: request) { (result) in
            completion(result)
        }
    }
}
