import Foundation
import PanelDesignKit

@main
enum PanelDesignDemo {

    static func main() async {
        do {
            try await run()
        } catch {
            print("demo failed: \(error)")
            exit(1)
        }
    }

    private static func run() async throws {
        print("PanelDesignKit — what a fixture can carry, decided before anything is measured on it")
        print(String(repeating: "=", count: 84))

        let crossed = try DemoPanels.fullyCrossed(judges: 3, repeats: 25)
        let ternary = try DemoPanels.ternary(items: 200, seed: 4_242)
        let constant = try DemoPanels.constantJudge(items: 200, otherPositives: 130)
        let builder = try BinaryPanelBuilder(
            first: try MarginalProfile.binary(positives: 121, items: 200),
            second: try MarginalProfile.binary(positives: 110, items: 200)
        )

        print(try DemoScenarios.crossedFixture(crossed))
        print(try DemoScenarios.attainable([
            PanelSpec(name: "two strict gates", items: 200, first: 176, second: 170),
            PanelSpec(name: "the demo pair", items: 200, first: 121, second: 110),
            PanelSpec(name: "balanced", items: 200, first: 100, second: 100),
            PanelSpec(
                name: "one constant judge", items: 200, first: 200,
                second: try constant.margin(1).counts[0]
            )
        ]))
        print(DemoScenarios.lattice(builder))
        print(try DemoScenarios.construction(builder))
        print(DemoScenarios.plackettBranches(first: 0.7, second: 0.7))
        print(await DemoScenarios.refusals(builder, ternary, crossed))
        print(try await DemoScenarios.ledger(crossed, seed: 20_260_907))
        print("\nDone.")
    }
}
