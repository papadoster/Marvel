//
//  MainCollectionViewController.swift
//  Marvel
//
//  Created by Александр Карпов on 09.05.2023.
//

import UIKit

private let reuseIdentifier = "Cell"

class MainCollectionViewController: UICollectionViewController {
    
    private var networkManager = NetworkManager()
    
    private var characters = [Result]()
    private var progressView = UIProgressView()
    private var image = UIImageView()
    private var responseCounting: [URLResponse] = []
    private var isImageNotAvailable: Bool = false
    
    private var widthCell: CGFloat = 0
    private var heightCell: CGFloat = 0
    private var grid = 2
    
    @IBOutlet weak var gridButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        widthCell = (view.frame.width - 60) / 2
        heightCell = (widthCell / 3 * 4) + 30
        
        progressView.tintColor = .white
        view.backgroundColor = .red
        
        progressView.frame = CGRect(x: (view.frame.width / 2) - 100, y: view.frame.height / 2, width: 200, height: 2)
        
        image.frame = CGRect(x: (view.frame.width / 2) - 100 , y: view.frame.height / 2 - 100, width: 200, height: 100)
        image.contentMode = .scaleAspectFit
        image.image = UIImage(named: "Marvel")!
        view.addSubview(image)
        view.addSubview(progressView)
        fetchDataFirstTime(offset: 0)
    }
    
    
    @IBAction func gridButtonPressed(_ sender: UIBarButtonItem) {
        switch grid {
        case 1 :
            gridButton.image = UIImage(systemName: "square.grid.3x2")
            grid = 2
            widthCell = (self.view.frame.width - 60) / 2
            heightCell = (widthCell / 3 * 4) + 30
            collectionView.reloadData()
        case 2 :
            gridButton.image = UIImage(systemName: "square")
            grid = 3
            widthCell = (self.view.frame.width - 80) / 3
            heightCell = (widthCell / 3 * 4) + 20
            collectionView.reloadData()
        case 3 :
            gridButton.image = UIImage(systemName: "square.grid.2x2")
            grid = 1
            widthCell = (self.view.frame.width - 40)
            heightCell = (widthCell / 3 * 4) + 40
            collectionView.reloadData()
        default:
            return
        }
    }
    
    //MARK: - fetchData
    
    func fetchDataFirstTime(offset: Int) {
        
        NetworkManager.getRequest(offset: offset) { characters in
            for character in characters {
                let urlImage = character.thumbnail.path
                let newUrl = self.urlFormatter(url: urlImage, extention: character.thumbnail.thumbnailExtension)
                self.networkManager.downloadImage(url: newUrl, isNotAvailable: self.isImageNotAvailable) { image in
                    
                } complitionResponse: { response in
                    self.responseCounting.append(response)
                    self.checkResponceCounting()
                }

            }
            self.characters.append(contentsOf: characters)
            self.checkResponceCounting()
        }
    }
    
    func fetchData(offset: Int) {
        
        NetworkManager.getRequest(offset: offset) { characters in
            for character in characters {
                let urlImage = character.thumbnail.path
                let newUrl = self.urlFormatter(url: urlImage, extention: character.thumbnail.thumbnailExtension)
                self.networkManager.downloadImage(url: newUrl, isNotAvailable: self.isImageNotAvailable) { _ in } complitionResponse: { _ in }

            }
            self.characters.append(contentsOf: characters)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
        }
    }
    
    func checkResponceCounting() {

        let numOfDownloaded = responseCounting.count
        DispatchQueue.main.async {
            self.progressView.progress = 1 / Float(21 - numOfDownloaded)
        }
        print(numOfDownloaded)
        if numOfDownloaded >= 20 {
            DispatchQueue.main.async {
                self.progressView.removeFromSuperview()
                self.image.removeFromSuperview()
                self.collectionView.reloadData()
            }
        }
    }
    
    //MARK: - configureCell
    
    private func configureCell(cell: CollectionViewCell, for indexPath: IndexPath) {
        
        let char = characters[indexPath.row]
        let urlImage = char.thumbnail.path
        let newUrl = urlFormatter(url: urlImage, extention: char.thumbnail.thumbnailExtension)
        
        cell.nameLabel.text = char.name
        let width = (self.view.frame.width - 60) / 2
        cell.image.frame = CGRect(x: 0, y: 0, width: width, height: width / 3 * 4)
        
        networkManager.downloadImage(url: newUrl, isNotAvailable: isImageNotAvailable) { image in
            DispatchQueue.main.async {
                cell.image.image = image
            }
        } complitionResponse: { _ in }
    }
    
    private func urlFormatter(url: String, extention: String) -> String {
        let stringArr = url.components(separatedBy: "://")
        if let body = stringArr.last {
            let newUrl = "https://\(body).\(extention)"
            
            if newUrl.contains("image_not_available") {
                isImageNotAvailable = true
            } else {
                isImageNotAvailable = false
            }
            
            print(newUrl)
            return newUrl
        }
        return url
    }
    
    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return characters.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        
        configureCell(cell: cell, for: indexPath)
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let number = characters.count - 10
        if indexPath.row == number {
            fetchData(offset: characters.count)
        }
        
    }

}

extension MainCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = (self.view.frame.width - 80) / 3
//        (width / 3 * 4) + 20
        return CGSize(width: widthCell, height: heightCell)
    }
}
