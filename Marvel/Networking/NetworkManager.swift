//
//  NetworkManager.swift
//  Marvel
//
//  Created by Александр Карпов on 09.05.2023.
//

import UIKit
import CryptoKit

class NetworkManager {
    
    var cache = NSCache<NSString, UIImage>()
    
    //MARK: - Get Request
    
    static func getRequest(offset: Int, completion: @escaping (_ characters: [Result]) -> ()) {
        
        let publicKey = Keys.publicKey
        let privateKey = Keys.privateKey
        let baseUrl = "https://gateway.marvel.com/v1/public/characters?limit=20"
        
        let ts = String(Date().timeIntervalSince1970)
        let hash = (ts + privateKey + publicKey).MD5

        let url = baseUrl + "&offset=\(offset)" + "&ts=" + ts + "&apikey=" + publicKey + "&hash=" + hash

        
        let session = URLSession.shared
        session.dataTask(with: URLRequest(url: URL(string: url)!)) { data, _, error in
            guard let data = data else { return }
            
            do {
                
                let character = try JSONDecoder().decode(Characters.self, from: data)
                print(character.data.results[0].name)
                completion(character.data.results)
                
            } catch {
                print(error)
            }
            
        }.resume()
    }
    
    //MARK: - DownloadImage
    
    func downloadImage(url: String, isNotAvailable: Bool, completion: @escaping (_ image: UIImage) -> (), complitionResponse: @escaping (_ response: URLResponse) -> ()) {
        
            if let imageCache = cache.object(forKey: NSString(string: url)) {
                print("cache hit")
                completion(imageCache)
                return
            }
            
            guard let realUrl = URL(string: url) else { return }
            
            let session = URLSession.shared
            
            session.dataTask(with: URLRequest(url: realUrl)) { data, response, error in
                if error != nil {
                    print(error!)
                }
                
                if let response = response {
                    complitionResponse(response)
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if isNotAvailable {
                            completion(UIImage(named: "ImageNotFound")!)
                        } else {
                            self.cache.setObject(image, forKey: NSString(string: url))
                            completion(image)
                        }
                    }
                }
            }
            .resume()
    }
}

//MARK: - extention String MD5

extension String {
var MD5: String {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}
