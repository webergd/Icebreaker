//
//  NetworkManage.swift
//  GithubFollowers
//
//  Created by Mahmudul Hasan on 2022-03-29.
//  Manages all network calls for the project

import UIKit

enum TError: Error {
    case invalidTask
    case invalidResponse
    case invalidData
    case other
}


class NetworkManager{
    
    static let shared = NetworkManager()
    
    private init(){
        
    }
    
    
    func getRegisteredContacts(for contacts: String, completed: @escaping (Result<[RegisteredUsers], TError>)->Void ){
        
        let endpoint = "https://us-central1-fir-poc-1594b.cloudfunctions.net/queryPhones"
        
        
        let url = URL(string: endpoint)!
        
        let params = ["phones": contacts]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error{
                completed(.failure(.invalidTask))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completed(.failure(.invalidData))
                return
            }
            
            do{
                let decoder = JSONDecoder()
                let root = try decoder.decode(Root.self, from: data)
                guard let users = root.data else {
                    completed(.failure(.other))
                    return
                    
                }
                
                completed(.success(users))
            }catch{
                completed(.failure(.invalidData))
            }
            
        }
        
        
        task.resume()
        
    }
    
    
}
