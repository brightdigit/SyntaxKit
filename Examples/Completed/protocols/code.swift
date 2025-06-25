// MARK: - Protocol Definition
protocol Vehicle {
    var numberOfWheels: Int { get }
    var brand: String { get }
    func start()
    func stop()
}

// MARK: - Protocol Extension
extension Vehicle {
    func start() {
        print("Starting \(brand) vehicle...")
    }

    func stop() {
        print("Stopping \(brand) vehicle...")
    }
}

// MARK: - Protocol Composition
protocol Electric {
    var batteryLevel: Double { get set }
    func charge()
}

// MARK: - Concrete Types
struct Car: Vehicle {
    let numberOfWheels: Int = 4
    let brand: String

    func start() {
        print("Starting \(brand) car engine...")
    }
}

struct ElectricCar: Vehicle, Electric {
    let numberOfWheels: Int = 4
    let brand: String
    var batteryLevel: Double

    func charge() {
        print("Charging \(brand) electric car...")
        batteryLevel = 100.0
    }
}

// MARK: - Usage Example
let tesla = ElectricCar(brand: "Tesla", batteryLevel: 75.0)
let toyota = Car(brand: "Toyota")

// Demonstrate protocol usage
func demonstrateVehicle(_ vehicle: Vehicle) {
    print("Vehicle brand: \(vehicle.brand)")
    print("Number of wheels: \(vehicle.numberOfWheels)")
    vehicle.start()
    vehicle.stop()
}

// Demonstrate protocol composition
func demonstrateElectricVehicle(_ vehicle: Vehicle & Electric) {
    demonstrateVehicle(vehicle)
    print("Battery level: \(vehicle.batteryLevel)%")
    vehicle.charge()
}

// Test the implementations
print("Testing regular car:")
demonstrateVehicle(toyota)

print("\nTesting electric car:")
demonstrateElectricVehicle(tesla)
