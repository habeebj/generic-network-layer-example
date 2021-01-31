//
//  GithubSerachResponseModel.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import Foundation

struct Repo: Codable, Identifiable {
    var id: Int
    let owner: Owner
    let name: String
    let description: String?

    struct Owner: Codable {
        let avatar: URL

        enum CodingKeys: String, CodingKey {
            case avatar = "avatar_url"
        }
    }
}

struct GithubSerachResponseModel: Codable {
    let items: [Repo]
}
