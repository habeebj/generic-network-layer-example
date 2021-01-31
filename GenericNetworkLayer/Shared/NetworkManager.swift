//
//  NetworkManager.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation
import UIKit

class NetworkManager {
    
    public static let shared: NetworkManager = NetworkManager()
    
    fileprivate var decoder: JSONDecoder
    
    var isRefreshing = false
    
    init() {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        self.decoder = decoder
    }
    
    public let baseURL: String = {
        return "https://api.github.com"
        // return Bundle.main.object(forInfoDictionaryKey: "ServerUrl") as! String
    }()
    
    private static let imageServiceCache = NSCache<NSString, UIImage>()
}

extension NetworkManager {
    
    fileprivate func send(request: RequestModelProtocol, completion: @escaping(Result<Data?, NetworkError>) -> Void) {
        URLSession.shared.dataTask(with: request.urlRequest()) { (data, response, error) in
            
            //            if self.isRefreshing && request.needsAuthorization() {
            //                // wait for two seconds and resend the request
            //                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //                    self.send(request: request, completion: completion)
            //                }
            //                return
            //            }
            
            // check if access token has expired and it is not refreshing
            // for refreshing accessToken will comment it out
            //            if LoginManager.shared.isAccessTokenExpired() && request.needsAuthorization() && !self.isRefreshing {
            //                self.isRefreshing = true
            //                LoginManager.shared.refreshAccessToken { (result) in
            //                    switch result {
            //                    case .success(_):
            //                        // resend the request
            //                        self.isRefreshing = false
            //                        self.send(request: request, completion: completion)
            //                        return
            //                    case .failure(let error):
            //                        self.isRefreshing = false
            //                        completion(.failure(error))
            //                        return
            //                    }
            //                }
            //                return
            //            }
            
            // if true, make refreshToken request then continue the existing request
            if error != nil, let nsError = error as NSError? {
                // -1001 - server not reachable
                // -1004 - server not rechable
                if nsError.code == -1009 {
                    DispatchQueue.main.async {
                        completion(.failure(.noConnectivity))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.unknown))
                    }
                }
                return
            }
            
            let response = response as! HTTPURLResponse
            // if let data = data, let dataString = String(data: data, encoding: .utf8) {
            //      print(dataString)
            // }
            
            // status code 401 = Not authorized
            if response.statusCode == 401 {
                // this depends on the api documentation
                // if response header contain token expired - Refresh token
                if response.allHeaderFields["Token-Expired"] != nil {
                    // for refreshing accessToken will comment it out
                    //                    LoginManager.shared.refreshAccessToken { (result) in
                    //                        switch result {
                    //                        case .success(_):
                    //                            // resend request
                    //                            self.send(request: request, completion: completion)
                    //                        case .failure(let error):
                    //                            completion(.failure(error))
                    //                            return
                    //                        }
                    //                    }
                }
                else
                {
                    completion(.failure(.unAuthorized))
                    return
                }
            } else {
                
                // print(response.statusCode)
                // if let data = data, let dataString = String(data: data, encoding: .utf8) {
                //      print(dataString)
                // }
                
                // TODO: 415 - unsorported media type
                
                guard (200...299).contains(response.statusCode) else {
                    DispatchQueue.main.async {
                        var networkError: NetworkError
                        
                        if response.statusCode == 502 {
                            networkError = .serverDown
                        } else if response.statusCode >= 400 && response.statusCode < 500 {
                            // 4xx -> something went wrong => Log
                            // parse response body for error message string
                            var bodyString: String = ""
                            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                                bodyString = dataString
                            }
                            networkError = .resourceError(bodyString)
                        } else {
                            // >500 return server error
                            networkError = .serverError
                        }
                        completion(.failure(networkError))
                    }
                    return
                }
                
                // everything is fine
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            }
        }.resume()
    }
    
    // For Web API calls with no return data
    func send(rawResponseWithRequest request: RequestModel, completion: @escaping(Result<String?, NetworkError>) -> Void) {
        
        send(request: request) { (result) in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        completion(.success(dataString))
                    } else {
                        completion(.success(nil))
                    }
                }
            case .failure(let networkError):
                DispatchQueue.main.async {
                    completion(.failure(networkError))
                }
            }
            return
        }
    }
    
    // Form data upload
    func send(rawResponseWithFormDataRequest request: FormDataRequestModel, completion: @escaping(Result<String?, NetworkError>) -> Void) {
        
        send(request: request) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        completion(.success(dataString))
                    } else {
                        completion(.success(nil))
                    }
                }
            case .failure(let networkError):
                DispatchQueue.main.async {
                    completion(.failure(networkError))
                }
            }
            return
        }
        
    }
    
    enum DateError: String, Error {
        case invalidDate
    }
    
    func send<T: Codable>(withFormDataRequest request: FormDataRequestModel, completion: @escaping(Result<T, NetworkError>) -> Void) {
        
        send(request: request) { result in
            switch result {
            case .success(let data):
                
                
                guard let data = data, let responseModel = try? self.decoder.decode(T.self, from: data) else {
                    DispatchQueue.main.async {
                        completion(.failure(.parsingError))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(.success(responseModel))
                }
            case .failure(let networkError):
                DispatchQueue.main.async {
                    completion(.failure(networkError))
                }
            }
            return
        }
        
    }
    
    func send<T: Codable>(request: RequestModel, completion: @escaping(Result<T, NetworkError>) -> Void) {
        
        send(request: request) { result in
            switch result {
            case .success(let data):
                guard let data = data, let responseModel = try? self.decoder.decode(T.self, from: data) else {
                    DispatchQueue.main.async {
                        completion(.failure(.parsingError))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(.success(responseModel))
                }
            case .failure(let networkError):
                DispatchQueue.main.async {
                    completion(.failure(networkError))
                }
            }
            return
        }
        
    }
    
    func getImage(fromUrl urlString: String, completion: @escaping(Result<UIImage, NetworkError>) -> Void) {
        if let imageFromCache = NetworkManager.imageServiceCache.object(forKey: urlString as NSString) {
            completion(.success(imageFromCache))
            return
        }
        
        guard let imageURL = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(.failure(.badUrl))
            }
            return
        }
        URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            guard let imageData = data else {
                DispatchQueue.main.async {
                    completion(.failure(.badUrl))
                }
                return
            }
            if let imageToCache = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    NetworkManager.imageServiceCache.setObject(imageToCache, forKey: urlString as NSString)
                    completion(.success(imageToCache))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.parsingError))
                }
            }
        }.resume()
    }
}
