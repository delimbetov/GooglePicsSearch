//
//  ImageCollectionViewCell.swift
//  GooglePicsSearch
//
//  Created by Кирилл Делимбетов on 17.02.17.
//  Copyright © 2017 Кирилл Делимбетов. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    //MARK: public
    static let identifier = "Image"
    
    var image: UIImage? {
        didSet {
            imageView.image = image
            activityIndicator.stopAnimating()
        }
    }
    var url: URL? {
        didSet {
            if url != nil {
                image = nil
                activityIndicator.startAnimating()
            }
        }
    }
    
    //MARK: Outlets
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!
    
}
