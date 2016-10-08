//
//  RecordingsCollectionViewController.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 08/10/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import UIKit


protocol RecordingsCollectionViewControllerDelegate {
    func recordingCollectionDidDismiss(_ viewController: RecordingsCollectionViewController)
}

class RecordingsCollectionViewController : UICollectionViewController {
    
    var delegate: RecordingsCollectionViewControllerDelegate?
    
    @IBAction func actionDone(_ sender: AnyObject) {
        delegate?.recordingCollectionDidDismiss(self)
    }
}
