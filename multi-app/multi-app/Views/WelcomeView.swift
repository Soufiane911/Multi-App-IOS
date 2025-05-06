import SwiftUI
import UIKit

struct WelcomeView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var animateElements = false
    @State private var showFeatures = false
    
    var body: some View {
        ZStack {
            // Fond avec dégradé bleu
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.teal.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Éléments flottants animés
            CirclesBackground()
            
            // Contenu principal
            VStack(spacing: 40) {
                Spacer()
                
                // Logo et titre
                VStack(spacing: 25) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                    .scaleEffect(animateElements ? 1 : 0.8)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateElements)
                    
                    Text("MultiProd")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateElements)
                    
                    Text("Vos outils de productivité réunis dans une seule application")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateElements)
                }
                
                // Fonctionnalités
                if showFeatures {
                    VStack(spacing: 15) {
                        FeatureRow(icon: "list.bullet.clipboard", color: .blue, title: "Gestion des tâches")
                        FeatureRow(icon: "calendar.badge.clock", color: .teal, title: "Suivi des habitudes")
                        FeatureRow(icon: "note.text", color: .cyan, title: "Notes rapides")
                        FeatureRow(icon: "chart.bar", color: .blue.opacity(0.7), title: "Statistiques personnelles")
                    }
                    .padding(.vertical)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Bouton
                Button {
                    withAnimation(.spring()) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Commencer")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 30)
                }
                .offset(y: animateElements ? 0 : 40)
                .opacity(animateElements ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: animateElements)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateElements = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring()) {
                    showFeatures = true
                }
            }
        }
    }
}

// Composant pour les fonctionnalités
struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 3)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// Cercles animés en arrière-plan
struct CirclesBackground: View {
    // Utilisons une palette de couleurs bleues uniquement
    let colors: [Color] = [.blue, .teal, .cyan.opacity(0.8), .blue.opacity(0.6)]
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .fill(colors[i % colors.count].opacity(0.3))
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 20)
            }
        }
    }
}

#Preview {
    WelcomeView(hasCompletedOnboarding: .constant(false))
} 