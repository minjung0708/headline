//
//  HeadlineView.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import SwiftUI

struct HeadlineView: View {
    @StateObject var viewModel: HeadlineViewModel
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.headlines) { headline in
                        NavigationLink(destination: HeadlineContentView(headline: headline)
                            .navigationBarBackButtonHidden()
                        ) {
                            HeadlineItemView(headline: headline)
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width)
                .background(
                    Color.gray.opacity(0.1)
                )
                .navigationTitle("News Today🗞️")
                .navigationBarTitleDisplayMode(.automatic)
            }
        }
    }
}

struct HeadlineItemView: View {
    var headline: Headline
    @State private var visited = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = headline.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                ZStack {
                    Color.gray.opacity(0.5)
                    Text("Image not founded")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            }
            
            if let title = headline.title {
                HStack {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(visited ? .red : .black)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            
            if let publised = headline.publishedAtText {
                HStack {
                    Text(publised)
                        .lineLimit(1)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 15)
            }
        }
        .background(
            Color.white
        )
        .onAppear {
            visited = StorageUtil.shared.checkUserDefaults(headline)
        }
    }
}

#Preview {
    HeadlineView(viewModel: HeadlineViewModel())
}
