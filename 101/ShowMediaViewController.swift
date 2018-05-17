//
//  ShowMediaViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-05-17.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import UIKit

class ShowMediaViewController: UIViewController {
    var image: UIImage? = nil

    
    @IBOutlet weak var imageView: UIImageView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if image != nil {
            imageView.image = image
        } else {
            print("image not found")
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
}
