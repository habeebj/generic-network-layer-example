//
//  RequestModel.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation

protocol RequestModelProtocol {
    func urlRequest() -> URLRequest
    //    func needsAuthorization() -> Bool
}

public enum RequestHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

class RequestModel {
    //    var _needAuthorization: Bool {
    //        return true
    //    }
    
    var path: String {
        return ""
    }
    var parameters: [String: String?] {
        return [:]
    }
    var headers: [String: String] {
        return ["content-type":"application/json"]
    }
    var method: RequestHTTPMethod {
        return body.isEmpty ? RequestHTTPMethod.get : RequestHTTPMethod.post
    }
    var body: [String: Any?] {
        return [:]
    }
    var data: Data? {
        return nil
    }
}


extension RequestModel: RequestModelProtocol {
    //    func needsAuthorization() -> Bool {
    //        return self._needAuthorization
    //    }
    
    func urlRequest() -> URLRequest {
        
        guard var endpoint = URLComponents(string: NetworkManager.shared.baseURL.appending(path))
        else { preconditionFailure("Can't create url components...") }
        
        let queryItems = parameters.map{ URLQueryItem(name: $0.key, value: $0.value)}
        endpoint.queryItems = queryItems
        
        guard let url = endpoint.url else { preconditionFailure("Can't get url from components...") }
        
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        // add authorization header to request
        // request.addValue(LoginManager.shared.getAuthorizationHeaderValue(), forHTTPHeaderField: "Authorization")
        
        if method == RequestHTTPMethod.post || method == RequestHTTPMethod.put {
            if let _data = data {
                request.httpBody = _data
            }
            else {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted)
                } catch let error {
                    print(error.localizedDescription)
                    // LogManager.e("Request body parse error: \(error.localizedDescription)")
                }
            }
            
        }
        
        return request
    }
}

// For form data upload
class FormDataRequestModel: RequestModelProtocol {
    func needsAuthorization() -> Bool {
        return true
    }
    
    var formData: [FormData] = []
    
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    var parameters: [String: String] {
        return [:]
    }
    
    var headers: [String: String] {
        return ["Accept": "application/json"]
    }
    
    var method: RequestHTTPMethod {
        return .post
    }
    
}

extension FormDataRequestModel {
    
    func urlRequest() -> URLRequest {
        
        let boundary = generateBoundary()
        let endpoint: String = NetworkManager.shared.baseURL.appending(path)
        
        var request: URLRequest = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = method.rawValue
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // add authorization header
        // request.addValue(LoginManager.shared.getAuthorizationHeaderValue(), forHTTPHeaderField: "Authorization")
        
        let dataBody = createDataBody(withParameters: parameters, media: formData, boundary: boundary)
        request.httpBody = dataBody
        
        return request
    }
    
    fileprivate func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    fileprivate func createDataBody(withParameters params: [String: String], media: [FormData]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        for (key, value) in parameters {
            body.append(Data("--\(boundary + lineBreak)".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".utf8))
            body.append(Data("\(value + lineBreak)".utf8))
        }
        
        if let media = media {
            for photo in media {
                body.append(Data("--\(boundary + lineBreak)".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.fileName)\"\(lineBreak)".utf8))
                body.append(Data("Content-Type: \(photo.mimeType + lineBreak + lineBreak)".utf8))
                body.append(photo.data)
                body.append(Data(lineBreak.utf8))
            }
        }
        
        body.append(Data("--\(boundary)--\(lineBreak)".utf8))
        
        return body
    }
}

struct FormData {
    let key: String
    let fileName: String
    let data: Data
    let mimeType: String
    
    init(withData data: Data, forKey key: String, fileExtension: String, mimeType: String) {
        self.key = key
        self.mimeType = mimeType
        self.fileName = "\(arc4random())\(fileExtension)"
        self.data = data
    }
}
