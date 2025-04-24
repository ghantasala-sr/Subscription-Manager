//
//  AIExplanationView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct AIExplanationView: View {
    @Binding var explanation: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with CoreML icon
                    HStack(spacing: 15) {
                        Image(systemName: "brain")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("CoreML Analysis")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Powered by on-device machine learning")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    if isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.top, 30)
                            
                            Text("Running subscription analysis...")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                        .onAppear {
                            // Simulate a brief loading time to show CoreML is "thinking"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    isLoading = false
                                }
                            }
                        }
                    } else {
                        Text(explanation)
                            .font(.body)
                            .lineSpacing(1.4)
                    }
                    
                    if !isLoading {
                        // Callout about CoreML
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About This Analysis")
                                .font(.headline)
                            
                            Text("This analysis was generated using on-device machine learning. Our CoreML model evaluates your subscription patterns, spending history, and other factors to provide personalized insights without sending your data to external servers.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}