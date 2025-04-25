//
//  OffersView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/25/25.
//


import SwiftUI

struct OffersView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var selectedOffer: SubscriptionOffer? = nil
    @State private var isCopied = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // User greeting
                    welcomeHeader

                    // Featured offer
                    if let featured = featuredOffer {
                        featuredOfferCard(featured)
                    }

                    // Categorized offers
                    Text("Popular Offers")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    ForEach(offersByCategory.keys.sorted(), id: \.self) { category in
                        if let offers = offersByCategory[category], !offers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(offers) { offer in
                                            offerCard(offer)
                                                .onTapGesture {
                                                    selectedOffer = offer
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Limited time offers
                    Text("Limited Time Offers")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    limitedTimeOffersList
                }
                .padding(.vertical)
            }
            .navigationTitle("Offers")
        }
        // Present detail sheet when selectedOffer is non-nil
        .sheet(item: $selectedOffer) { offer in
            NavigationView {
                OfferDetailView(offer: offer, isCopied: $isCopied)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                selectedOffer = nil
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Subviews

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let user = authService.currentUser, let firstName = user.firstName {
                Text("Hey \(firstName)!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.horizontal)
            } else {
                Text("Special Offers")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.horizontal)
            }

            Text("Discover savings on your subscriptions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    private func featuredOfferCard(_ offer: SubscriptionOffer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(offer.backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()

                Text("\(offer.discountPercentage)% OFF")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(4)
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(offer.title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(offer.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    if let promoCode = offer.promoCode {
                        HStack {
                            Text(promoCode)
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)

                            Button(action: {
                                UIPasteboard.general.string = promoCode
                                withAnimation {
                                    isCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        isCopied = false
                                    }
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Spacer()

                    Text("Valid until \(formattedDate(offer.validUntil))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func offerCard(_ offer: SubscriptionOffer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(offer.brandColor)
                    .frame(width: 50, height: 50)

                Text("\(offer.discountPercentage)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(offer.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if let promoCode = offer.promoCode {
                Text(promoCode)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(3)
            }

            Text(formattedShortDate(offer.validUntil))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var limitedTimeOffersList: some View {
        VStack(spacing: 15) {
            ForEach(limitedTimeOffers) { offer in
                HStack {
                    if let icon = offer.serviceIcon {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(offer.brandColor)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(offer.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(offer.discountPercentage)% OFF")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        Text(timeRemaining(until: offer.validUntil))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
                .onTapGesture {
                    selectedOffer = offer
                }
            }
        }
    }

    // MARK: - Helpers
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func timeRemaining(until date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        if let days = components.day {
            if days <= 0 {
                return "Expires today"
            } else if days == 1 {
                return "1 day left"
            } else {
                return "\(days) days left"
            }
        }
        return "Limited time"
    }

    // MARK: - Sample Data
    private var featuredOffer: SubscriptionOffer? {
        allOffers.max(by: { $0.discountPercentage < $1.discountPercentage })
    }

    private var offersByCategory: [String: [SubscriptionOffer]] {
        Dictionary(grouping: allOffers.filter { $0.id != featuredOffer?.id }, by: { $0.category })
    }

    private var limitedTimeOffers: [SubscriptionOffer] {
        let calendar = Calendar.current
        let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: Date())!
        return allOffers.filter { $0.validUntil < sevenDaysFromNow }
    }

    private var allOffers: [SubscriptionOffer] = [
        SubscriptionOffer(
            id: "netflix-50",
            title: "Netflix Premium Plan",
            description: "Get 50% off your first 3 months of Netflix Premium",
            category: "Streaming",
            discountPercentage: 50,
            validUntil: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
            backgroundImage: "netflix_offer",
            brandColor: .red,
            serviceIcon: "play.tv.fill",
            promoCode: "NETFLIX50"
        ),
        SubscriptionOffer(
                   id: "spotify-family",
                   title: "Spotify Family Plan",
                   description: "30% off Family Plan for 6 months when you upgrade",
                   category: "Music",
                   discountPercentage: 30,
                   validUntil: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
                   backgroundImage: "spotify_offer",
                   brandColor: .green,
                   serviceIcon: "music.note",
                   promoCode: "FAMILYMUSIC"
               ),
               SubscriptionOffer(
                   id: "disney-annual",
                   title: "Disney+ Annual Plan",
                   description: "Save 15% with annual billing",
                   category: "Streaming",
                   discountPercentage: 15,
                   validUntil: Calendar.current.date(byAdding: .day, value: 60, to: Date())!,
                   backgroundImage: "disney+_offer",
                   brandColor: .blue,
                   serviceIcon: "film.fill",
                   promoCode: nil
               ),
               SubscriptionOffer(
                   id: "adobe-student",
                   title: "Adobe Creative Cloud",
                   description: "65% off for students and teachers",
                   category: "Software",
                   discountPercentage: 65,
                   validUntil: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                   backgroundImage: "adobe_offer",
                   brandColor: .orange,
                   serviceIcon: "pencil.and.ruler",
                   promoCode: "ADOBESTUDENT"
               ),
               SubscriptionOffer(
                   id: "youtube-trial",
                   title: "YouTube Premium",
                   description: "3 months free trial, then 20% off first year",
                   category: "Streaming",
                   discountPercentage: 20,
                   validUntil: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                   backgroundImage: "youtube_offer",
                   brandColor: .red,
                   serviceIcon: "play.rectangle.fill",
                   promoCode: "YTPREMIUM"
               ),
               SubscriptionOffer(
                   id: "apple-bundle",
                   title: "Apple One Bundle",
                   description: "First month free when you subscribe to Apple One",
                   category: "Services",
                   discountPercentage: 100,
                   validUntil: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                   backgroundImage: "apple_offer",
                   brandColor: .gray,
                   serviceIcon: "applelogo",
                   promoCode: nil
               ),
               SubscriptionOffer(
                   id: "hbo-offer",
                   title: "HBO Max Discount",
                   description: "Sign up for 12 months and get 2 months free",
                   category: "Streaming",
                   discountPercentage: 17,
                   validUntil: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                   backgroundImage: "hbo_offer",
                   brandColor: .purple,
                   serviceIcon: "tv",
                   promoCode: "HBO2FREE"
               ),
               SubscriptionOffer(
                   id: "nytimes-digital",
                   title: "NY Times Digital",
                   description: "First 3 months at 75% off the regular rate",
                   category: "News",
                   discountPercentage: 75,
                   validUntil: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                   backgroundImage: "nytimes_offer",
                   brandColor: .black,
                   serviceIcon: "newspaper.fill",
                   promoCode: "NYTDIGITAL"
               )
        // other offers...
    ]
}

struct OfferDetailView: View {
    let offer: SubscriptionOffer
    @Binding var isCopied: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Image(offer.backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        HStack {
                            Text("\(offer.discountPercentage)% OFF")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .cornerRadius(4)

                            Spacer()

                            Text("Valid until \(formattedDate(offer.validUntil))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("Offer Details")
                        .font(.headline)

                    Text(offer.description)
                        .font(.body)

                    Text("Terms & Conditions")
                        .font(.headline)

                    Text("This offer is valid for new and eligible returning subscribers only. Cannot be combined with any other offers. The discount applies to the duration specified in the offer details. After the promotional period, standard pricing applies unless cancelled.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let promoCode = offer.promoCode {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Promo Code")
                                .font(.headline)

                            HStack {
                                Text(promoCode)
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(8)

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = promoCode
                                    withAnimation {
                                        isCopied = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isCopied = false
                                        }
                                    }
                                }) {
                                    Text(isCopied ? "Copied!" : "Copy")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(isCopied ? .green : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isCopied ? Color.green.opacity(0.2) : Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                    }

                    VStack(spacing: 15) {
                        Button(action: {
                            // Redeem logic
                        }) {
                            Text("Redeem Offer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: { dismiss() }) {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Offer Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SubscriptionOffer: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: String
    let discountPercentage: Int
    let validUntil: Date
    let backgroundImage: String
    let brandColor: Color
    let serviceIcon: String?
    let promoCode: String?
}
