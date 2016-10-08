//
//  RecordingsCollectionViewController.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 08/10/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

protocol RecordingsCollectionViewControllerDelegate {
    func recordingCollectionDidDismiss(_ viewController: RecordingsCollectionViewController)
}

class RecordingsCollectionViewController : UICollectionViewController {
    
    var delegate: RecordingsCollectionViewControllerDelegate?
    
    fileprivate var assets: [AVAsset] = []
    fileprivate let collection = RecordingsCollection()
    
    override func viewDidLoad() {
        assets = collection.recordings()
    }
}

// MARK: Actions
extension RecordingsCollectionViewController {
    @IBAction func actionDone(_ sender: AnyObject) {
        delegate?.recordingCollectionDidDismiss(self)
    }
}

// MARK: UICollectionViewDataSource
extension RecordingsCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "movie", for: indexPath)
        let imageView: UIImageView = cell.contentView.subviews.filter { (subview) -> Bool in
            return subview is UIImageView
        }[0] as! UIImageView
        
        let asset = assets[indexPath.row]
        collection.queryThumbnail(forAsset: asset, maxSize: imageView.bounds.size) { (image) in
            if image != nil {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
        return cell
    }
}

extension RecordingsCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let playerViewController = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: assets[indexPath.row])
        playerViewController.player = AVPlayer(playerItem: playerItem)
        
        present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
}

