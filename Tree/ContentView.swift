import SwiftUI

extension Color {
    static let appBackground = Color(red: 0xF6 / 255, green: 0xF6 / 255, blue: 0xEA / 255)
}

struct ContentView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor(Color.appBackground)
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}
