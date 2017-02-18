//
//  ViewController.swift
//  GooglePicsSearch
//
//  Created by Кирилл Делимбетов on 12.02.17.
//  Copyright © 2017 Кирилл Делимбетов. All rights reserved.
//

import UIKit

class SearchImagesViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource {
    
    //MARK: Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var searchBar: UISearchBar!
   
    //MARK: private data
    private struct Constant {
        static let apiKey = "AIzaSyDYVOu0CC8-M6kqGg78CW2MctA2Df7Je8o"
        static let numberOfImagesPerQuery = 9
        static let maximumImagesPerSearch = 100
    }
    private var cache = NSCache<NSString, UIImage>()
    private var loading = false
    private var search: String? {
        didSet {
            urls.removeAll()
            loading = false
            
            if search?.isEmpty == false {
                askGoogleForMorePics()
            }
        }
    }
    private var urls = [URL]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    //MARK: private funcs
    private func askGoogleForMorePics() {
        var numberOfImagesPerQuery = Constant.numberOfImagesPerQuery
        guard let search = self.search else {
            print("self.search == nil, cant look for that")
            return
        }
        
        if Constant.maximumImagesPerSearch <= urls.count + numberOfImagesPerQuery {
            numberOfImagesPerQuery = Constant.maximumImagesPerSearch - urls.count
            
            if numberOfImagesPerQuery <= 0 {
                print("cannot load any more images for this search")
                return
            }
        }
        
        let urlString = "https://www.googleapis.com/customsearch/v1?q=\(search.replacingOccurrences(of: " ", with: "+"))&cx=005594313016221312182%3Avorw4qu0-xa&num=\(numberOfImagesPerQuery)&searchType=image&start=\(urls.count + 1)&key=\(Constant.apiKey)"
        
        print(urlString)
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { [weak weakSelf = self](data, response, error) in
                if error != nil {
                    print(error.debugDescription)
                    return
                }
                
                guard let data = data, let response = response, response is HTTPURLResponse else {
                    print("request err")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data), let rootDict = json as? [String: Any], let items = rootDict["items"] as? [Any] {
                    var imageUrls = [URL]()
                    
                    for item in items {
                        if let dict = item as? [String: Any], let link = dict["link"] as? String, let url = URL(string: link) {
                            imageUrls.append(url)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        if let currSearch = weakSelf?.search, currSearch == search {
                            weakSelf?.urls.append(contentsOf: imageUrls)
                            weakSelf?.loading = false
                        }
                    }
                }
            }
            
            loading = true
            task.resume()
        }
    }
    
    //MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        searchBar.delegate = self
    }
    
    //MARK: UISearchBarDelegate
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        search = searchBar.text
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath)
        
        if urls.count - indexPath.row < Constant.numberOfImagesPerQuery && !loading {
            askGoogleForMorePics()
        }
        
        if let imagecell = cell as? ImageCollectionViewCell, indexPath.row < urls.count {
            let url = urls[indexPath.row]
            
            imagecell.url = url
            
            if let image = cache.object(forKey: url.absoluteString as NSString) {
                imagecell.image = image
            } else {
                DispatchQueue.global(qos: .default).async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async { [weak weakSelf = self] in
                            if let cellCurrUrl = imagecell.url, cellCurrUrl == url, let image = UIImage(data: data) {
                                weakSelf?.cache.setObject(image, forKey: cellCurrUrl.absoluteString as NSString, cost: data.count)
                                imagecell.image = image
                            }
                        }
                    } else {
                        print("failed download from \(url)")
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    
}

