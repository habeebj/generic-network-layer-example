//
//  ContentView.swift
//  SampleNetwork
//
//  Created by Habeeb Jimoh on 31/01/2021.
//

import SwiftUI

struct ContentView: View {
    @State var repos: [Repo] = []
    @State var status: String = "Loading"
    @State var query: String = "swift"
    
    var body: some View {
        NavigationView {
            List {
                TextField("Enter search query here", text: $query, onCommit:  {
                    self.fetch(query)
                })

                if repos.isEmpty {
                    Text(status)
                } else {
                    ForEach(repos, id: \.id) { repo in
                        RepoRow(repo: repo)
                    }
                }
            }
            .navigationTitle("Github Search")
            .onAppear(perform: {
                fetch(query)
            })
        }
    }
    
    private func fetch(_ q: String) {
        GithubService.shared.search(q) { (result) in
            switch result {
            case .success(let response):
                self.repos =  response.items
            case .failure(let error):
                self.status = error.localizedDescription
            }
        }
    }
}

struct RepoRow: View {
    let repo: Repo

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                Text(repo.description ?? "")
                    .font(.subheadline)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
