//
//  GithubSerachRequestModel.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation

class GithubSerachRequestModel: RequestModel {
    private let query: String
    
    init(query: String) {
        self.query = query
    }
    
    override var parameters: [String : String?] {
        // this will append ?q=query_string to the url
        return ["q": self.query]
    }
    
    // defualt method is GET
    override var method: RequestHTTPMethod {
        return .get
    }
    
    override var path: String {
        return "/search/repositories"
    }
    
    // To add body for post request
    //    override var body: [String : Any?] {
    //        return [
    //            "name1": "value1",
    //            "name2": "value2"
    //        ]
    //    }
    
    // To manually handle to encoding of objects
    //    override var data: Data? {
    //        let encoder = JSONEncoder()
    //        return try? encoder.encode(self.recipient)
    //    }
}
