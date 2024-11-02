//
//  ToastView.swift
//  headline
//
//  Created by MinJung on 11/1/24.
//

import SwiftUI

final class ToastViewController: UIHostingController<ToastView> {
    override init(rootView: ToastView) {
        super.init(rootView: rootView)
        view.backgroundColor = .clear
    }
    
    @available(*, unavailable)
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.Toast.background.opacity(0.9)
            Text(message)
                .font(Font.system(size: 15))
                .foregroundColor(Color.Toast.Text.content)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
        }
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
    }
}

#Preview {
    ToastView(message: "실시간 데이터 조회에 실패했습니다.\n기기에 저장된 데이터를 조회합니다.")
}
