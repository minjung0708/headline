//
//  HeadlineView.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import SwiftUI

enum Orientation {
    case portrait
    case landscape
}

struct HeadlineView: View {
    @StateObject var viewModel: HeadlineViewModel
    @State private var windowScene: UIWindowScene?
    @State private var isNotificationBinded: Bool = false
    @State private var orientation: Orientation = .portrait
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.headlines.isEmpty {
                    EmptyDataView(viewModel: viewModel)
                        .frame(width: screenSize.width, height: screenSize.height)
                } else {
                    switch orientation {
                    case .portrait:
                        PortraitView(viewModel: viewModel, width: screenSize.width)
                    case .landscape:
                        LandscapeView(viewModel: viewModel)
                    }
                }
            }
            .background(
                Color.ScrollView.background
            )
            .navigationTitle("News Today🗞️ (\(viewModel.totalCount))")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing) {
                        Button {
                            viewModel.changeCountry.send()
                        } label: {
                            switch viewModel.requestParam.country {
                            case .kr:
                                Text("🇰🇷")
                                    .font(.system(size: 26))
                            case .us:
                                Text("🇺🇸")
                                    .font(.system(size: 26))
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
            }
            .onAppear {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let firstWindowScene = scene.windows.first?.windowScene else { return }
                
                isNotificationBinded = true
                windowScene = firstWindowScene
                orientation = (firstWindowScene.interfaceOrientation.isPortrait ? .portrait : .landscape)
                screenSize = firstWindowScene.screen.bounds.size
            }
            .onDisappear {
                isNotificationBinded = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                guard let windowScene, isNotificationBinded == true else { return }
                orientation = (windowScene.interfaceOrientation.isPortrait ? .portrait : .landscape)
            }
            .onChange(of: orientation) { _ in
                guard let windowScene else { return }
                screenSize = windowScene.screen.bounds.size
            }
        }
    }
}

struct EmptyDataView: View {
    @StateObject var viewModel: HeadlineViewModel
    
    var body: some View {
        ZStack {
            Text("😢 Data is emtpy 📭")
                .font(.system(size: 20, weight: .semibold))
        }
    }
}

struct PortraitView: View {
    @StateObject var viewModel: HeadlineViewModel
    let width: CGFloat
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.headlines) { headline in
                    NavigationLink(destination: HeadlineContentView(headline: headline)
                        .navigationBarBackButtonHidden()
                    ) {
                        PortraitItemView(headline: headline, width: width)
                            .onAppear {
                                // 해당 아이템이 마지막 아이템일 때, 다음 페이지 데이터 호출
                                guard !viewModel.isLoading && viewModel.headlines.count < viewModel.totalCount else { return }
                                guard headline.id == viewModel.headlines.last?.id else { return }
                                viewModel.requestHeadlinesMore.send()
                            }
                    }
                }
            }
        }
    }
}

struct LandscapeView: View {
    @StateObject var viewModel: HeadlineViewModel
    private let columns: [GridItem] = Array(repeating: .init(.fixed(300), spacing: 10), count: 5)
    
    var body: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 15) {
                ForEach(viewModel.headlines) { headline in
                    NavigationLink(destination: HeadlineContentView(headline: headline)
                        .navigationBarBackButtonHidden()
                    ) {
                        LandscapeItemView(headline: headline)
                            .onAppear {
                                // 해당 아이템이 마지막 아이템일 때, 다음 페이지 데이터 호출
                                guard !viewModel.isLoading && viewModel.headlines.count < viewModel.totalCount else { return }
                                guard headline.id == viewModel.headlines.last?.id else { return }
                                viewModel.requestHeadlinesMore.send()
                            }
                    }
                }
            }
        }
    }
}

struct PortraitItemView: View {
    let headline: Headline
    let width: CGFloat
    @State private var isVisited = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = headline.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 200)
                    .clipped()
            } else {
                ZStack {
                    Color.Item.Image.background
                    Text("Image not found")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(width: width, height: 200)
            }
            
            if let title = headline.title {
                HStack {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isVisited ? .red : Color.Item.Text.title)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            
            if let publised = headline.publishedAtText {
                HStack {
                    Text(publised)
                        .lineLimit(1)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.Item.Text.publishedAt)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 15)
            }
        }
        .background(
            Color.Item.background
        )
        .onAppear {
            isVisited = StorageUtil.shared.checkUserDefaults(headline)
        }
    }
}

struct LandscapeItemView: View {
    let headline: Headline
    @State private var visited = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = headline.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 80)
                    .clipped()
            } else {
                ZStack {
                    Color.Item.Image.background
                    Text("Image not found")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(height: 80)
            }
            
            Spacer()
                .frame(height: 5)
            
            if let title = headline.title {
                HStack {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(visited ? .red : Color.Item.Text.title)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            
            if let publised = headline.publishedAtText {
                HStack {
                    Text(publised)
                        .lineLimit(1)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.Item.Text.publishedAt)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 300, height: 120)
        .background(
            Color.Item.background
        )
        .onAppear {
            visited = StorageUtil.shared.checkUserDefaults(headline)
        }
    }
}

#Preview {
    HeadlineView(viewModel: HeadlineViewModel())
}
