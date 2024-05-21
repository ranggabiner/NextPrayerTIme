import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = NextPrayerTimeLocationManager()
    @State private var prayerTime: String = "Loading..."
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text(prayerTime)
                .fontWeight(.semibold)
                .font(.system(size: 34))
                    .foregroundStyle(Color(hex: 0xA2FC06))        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(locationManager.$province) { _ in
            updatePrayerTime()
        }
        .onReceive(locationManager.$city) { _ in
            updatePrayerTime()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updatePrayerTime()
        }
    }
    
    private func updatePrayerTime() {
        guard let location = locationManager.location else {
            print("Location not available")
            return
        }
        
        if let prayerTimes = loadPrayerTimes(for: Date(), province: locationManager.province, city: locationManager.city) {
            prayerTime = getNextPrayerTime(currentTime: Date(), prayerTimes: prayerTimes)
        } else {
            prayerTime = "Error loading prayer times"
        }
    }
    
    private func getNextPrayerTime(currentTime: Date, prayerTimes: PrayerTimes) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        func timeToComponents(_ time: String) -> DateComponents? {
            guard let date = dateFormatter.date(from: time) else { return nil }
            return calendar.dateComponents([.hour, .minute], from: date)
        }
        
        func createDate(components: DateComponents) -> Date? {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentTime)
        }
        
        let prayerTimesList = [
            prayerTimes.fajr,
            prayerTimes.sunrise,
            prayerTimes.dhuhr,
            prayerTimes.asr,
            prayerTimes.maghrib,
            prayerTimes.isha
        ]
        
        for prayerTime in prayerTimesList {
            if let components = timeToComponents(prayerTime), let date = createDate(components: components), date > currentTime {
                return dateFormatter.string(from: date)
            }
        }
        
        // If the current time is past Isha, return the time for Fajr of the next day
        if let fajrComponents = timeToComponents(prayerTimes.fajr), let fajrDate = createDate(components: fajrComponents) {
            let nextDayFajrDate = calendar.date(byAdding: .day, value: 1, to: fajrDate)
            return nextDayFajrDate != nil ? dateFormatter.string(from: nextDayFajrDate!) : "Error"
        }
        
        return "Error"
    }
}

#Preview {
    ContentView()
}
