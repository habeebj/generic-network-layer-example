//
//  NetworkError.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation

enum NetworkError: Error {
    case badUrl
    case noConnectivity
    case parsingError
    case resourceError(String)
    // case badRequest(String)
    case serverError
    case serverDown
    case unknown
    case notFound
    case unAuthorized
}
