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
    func setFirebaseGsImage(for gsUrl: String) {
        

        let storage = FirebaseStorage.Storage.storage()
        let gsReference = storage.reference(forURL: gsUrl)

        gsReference.downloadURL { downloadUrl, downloadError in
            guard let downloadUrl = downloadUrl else {return}

            // checking cache manually
            if ImageCache.default.isCached(forKey: downloadUrl.absoluteString) {
                self.kf.setImage(
                    with: downloadUrl,
                    options: [
                        .processor(DownsamplingImageProcessor(size: self.bounds.size)),
                        .cacheOriginalImage
                    ]){
                        result in
                        switch result {
                            case .success(let success):
                                print("GS Task done: \(success.data()?.count)")
                            case .failure(let error):
                                print("GS Job failed: \(error.localizedDescription)")
                        }
                    }
                print("GS: Image Set Pre Downloaded")
                return
            }

            print("GS: Image Set Downloaded")
            self.kf.indicatorType = .activity
            self.kf.setImage(
                with: downloadUrl,
                placeholder: UIImage(named: "loading_large_black"),
                options: [
                    .processor(DownsamplingImageProcessor(size: self.bounds.size)),
                    .transition(.fade(0.1)),
                    .cacheOriginalImage
                ])
            {
                result in
                switch result {
                    case .success(_):
                        print("GS Task done")
                    case .failure(let error):
                        print("GS Job failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Sets an image to this image view
    /// - Parameter url: any https:// protocol based url
    /// - Parameter downSample: Indicates whether the image should be downsampled or resized, default value true
    func setFirebaseImage(for url: String) {
        print("loading profile image from firebase")
        let downloadUrl = URL(string: url)
        guard let downloadUrl = downloadUrl else {return}

        // checking cache manually
        if ImageCache.default.isCached(forKey: downloadUrl.absoluteString) {
            self.kf.setImage(
                with: downloadUrl,
                options: [
                    .processor(DownsamplingImageProcessor(size: self.bounds.size)),
                    .cacheOriginalImage
                ])
            print("HTTPS: Image Set Pre Downloaded")
            return
        }

        self.kf.indicatorType = .activity
        self.kf.setImage(
            with: downloadUrl,
            options: [
                .processor(DownsamplingImageProcessor(size: self.bounds.size)),
                .transition(.fade(0.1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
                case .success(_):
                    print("Task done")
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
            }
        }
    }
}
