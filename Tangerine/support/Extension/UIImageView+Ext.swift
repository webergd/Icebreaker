//
//  UIImageView+Ext.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2023-04-01.
//

import UIKit
import FirebaseStorage
import Kingfisher

extension UIImageView {

    /// Sets an image to this image view
    /// - Parameter gsUrl: firebase storage url starting with gs:// protocol, image only
    /// - Parameter downSample: Indicates whether the image should be downsampled or resized, default value true
    func setFirebaseGsImage(for gsUrl: String, downSample: Bool = true) {
        

        let storage = FirebaseStorage.Storage.storage()
        let gsReference = storage.reference(forURL: gsUrl)

        gsReference.downloadURL { downloadUrl, downloadError in
            guard let downloadUrl = downloadUrl else {return}
            let scale = UIScreen.main.scale
            let processor: ImageProcessor = downSample ? DownsamplingImageProcessor(size: CGSize(width: self.bounds.size.width * scale, height: self.bounds.size.height * scale)) : ResizingImageProcessor(referenceSize: self.bounds.size)

            self.kf.indicatorType = .activity
            self.kf.setImage(
                with: downloadUrl,
                placeholder: UIImage(named: "loading_large_black"),
                options: [
                    .processor(processor),
                    .scaleFactor(scale),
                    .transition(.fade(0.1)),
                    .cacheOriginalImage
                ])
            {
                result in
                switch result {
                    case .success(let value):
                        print("GS Task done for: \(value.data()?.count)")
                    case .failure(let error):
                        print("GS Job failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Sets an image to this image view
    /// - Parameter url: any https:// protocol based url
    /// - Parameter downSample: Indicates whether the image should be downsampled or resized, default value true
    func setFirebaseImage(for url: String, downSample: Bool = true) {
        print("loading profile image from firebase")
        let downloadUrl = URL(string: url)
        let scale = UIScreen.main.scale

        let processor: ImageProcessor  = downSample ? DownsamplingImageProcessor(size: CGSize(width: self.bounds.size.width * scale, height: self.bounds.size.height * scale)) : ResizingImageProcessor(referenceSize: self.bounds.size)

        self.kf.indicatorType = .activity
        self.kf.setImage(
            with: downloadUrl,
            options: [
                .processor(processor),
                .scaleFactor(scale),
                .transition(.fade(0.1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
                case .success(let value):
                    print("Task done for: \(value.data()?.count)")
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
            }
        }
    }
}
