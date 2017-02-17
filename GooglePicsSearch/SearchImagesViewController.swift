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
    private static let apiKey = "AIzaSyDYVOu0CC8-M6kqGg78CW2MctA2Df7Je8o"
    private var cache = NSCache<NSString, UIImage>()
    private var loading = false
    private static let numberOfImagesPerQuery = 10
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
        if let search = self.search, let url = URL(string: "https://www.googleapis.com/customsearch/v1?q=\(search.replacingOccurrences(of: " ", with: "+"))&cx=005594313016221312182%3Avorw4qu0-xa&num=\(SearchImagesViewController.numberOfImagesPerQuery)&searchType=image&start=\(urls.count + 1)&key=\(SearchImagesViewController.apiKey)") {
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
        
        if urls.count - indexPath.row < SearchImagesViewController.numberOfImagesPerQuery && !loading {
            askGoogleForMorePics()
        }
        
        if let imagecell = cell as? ImageCollectionViewCell, indexPath.row < urls.count {
            let url = urls[indexPath.row]
            
            imagecell.url = url
            
            if let image = cache.object(forKey: url.absoluteString as NSString) {
                imagecell.image = image
            } else {
                print("begins downloading from: \(url)")
                DispatchQueue.global(qos: .default).async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async { [weak weakSelf = self] in
                            if let cellCurrUrl = imagecell.url, cellCurrUrl == url, let image = UIImage(data: data) {
                                weakSelf?.cache.setObject(image, forKey: cellCurrUrl.absoluteString as NSString, cost: data.count)
                                imagecell.image = image
                            }
                        }
                    } else {
                        print("failure")
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

