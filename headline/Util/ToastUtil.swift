//
//  ToastUtil.swift
//  headline
//
//  Created by MinJung on 11/1/24.
//

import Foundation
import UIKit

class ToastUtil {
    static let shared = ToastUtil()
    private init() { }
}

extension ToastUtil {
    func show(msg: String, dismissAfter: CGFloat = 2) {
        let viewController = ToastViewController(rootView: ToastView(message: msg))
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let windowScene = scene.windows.first?.windowScene,
              let keyWindow = windowScene.keyWindow,
              let rootViewController = keyWindow.rootViewController,
              let rootView = rootViewController.view,
              let childView = viewController.view else { return }
        
        rootViewController.addChild(viewController)
        rootViewController.view.addSubview(childView)
        
        let bottomSafeArea = keyWindow.safeAreaInsets.bottom
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        
        [childView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
         childView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
         childView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -(bottomSafeArea + 20))]
            .forEach { $0.isActive = true }
        
        childView.alpha = 0.0
        
        UIView.animate(withDuration: 0.35) {
            childView.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
            UIView.animate(withDuration: 0.35) {
                childView.alpha = 0.0
            } completion: { _ in
                childView.removeFromSuperview()
                viewController.removeFromParent()
            }
        }
    }
}
