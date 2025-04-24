//
//  LogoImageView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct LogoImageView: View {
    let logoName: String
    let size: CGFloat
    
    var body: some View {
        if let uiImage = UIImage(named: logoName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .cornerRadius(8)
        } else {
            // Fallback to a default logo if the named image doesn't exist
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                
                Text(String(logoName.prefix(1).uppercased()))
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
    }
}