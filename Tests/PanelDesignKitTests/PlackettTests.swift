import Foundation
import Testing
@testable import PanelDesignKit

@Suite("Plackett's root")
struct PlackettTests {

    private func impliedOddsRatio(_ joint: Double, _ p1: Double, _ p2: Double) -> Double {
        joint * (1 - p1 - p2 + joint) / ((p1 - joint) * (p2 - joint))
    }

    @Test func independenceIsTheProductWithNoSpecialCase() {
        let value = PlackettRoot.jointProbability(oddsRatio: 1, first: 0.7, second: 0.6)
        #expect(abs(value - 0.42) < 1e-15)
        #expect(PlackettRoot.evaluate(.rationalised, oddsRatio: 1, first: 0.7, second: 0.6) == 0.42)
        #expect(PlackettRoot.evaluate(.textbook, oddsRatio: 1, first: 0.7, second: 0.6) == 0.42)
    }

    @Test(arguments: [1e-9, 1e-6, 0.001, 0.5, 1.0, 2.0, 4.0, 100.0, 1e6])
    func theSelectedBranchReproducesItsOwnOddsRatio(psi: Double) {
        for (p1, p2) in [(0.7, 0.7), (0.605, 0.55), (0.2, 0.3), (0.9, 0.15)] {
            let joint = PlackettRoot.jointProbability(oddsRatio: psi, first: p1, second: p2)
            #expect(joint >= max(0, p1 + p2 - 1) - 1e-12)
            #expect(joint <= min(p1, p2) + 1e-12)
            let residual = abs(impliedOddsRatio(joint, p1, p2) - psi) / psi
            #expect(residual < 1e-6, "psi \(psi) rates \(p1)/\(p2) residual \(residual)")
        }
    }

    /// The failure that makes the branch selector necessary rather than tidy.
    @Test func eachBranchIsWrongWhereTheOtherIsRight() {
        let textbookNearOne = PlackettRoot.evaluate(
            .textbook, oddsRatio: 1 - 1e-13, first: 0.7, second: 0.7
        )
        #expect(abs(textbookNearOne - 0.49) / 0.49 > 1e-6)
        let rationalisedFarBelow = PlackettRoot.evaluate(
            .rationalised, oddsRatio: 1e-9, first: 0.7, second: 0.7
        )
        #expect(abs(impliedOddsRatio(rationalisedFarBelow, 0.7, 0.7) - 1e-9) / 1e-9 > 1)
        let selectedNearOne = PlackettRoot.jointProbability(
            oddsRatio: 1 - 1e-13, first: 0.7, second: 0.7
        )
        #expect(abs(selectedNearOne - 0.49) / 0.49 < 1e-12)
        let selectedFarBelow = PlackettRoot.jointProbability(
            oddsRatio: 1e-9, first: 0.7, second: 0.7
        )
        #expect(abs(impliedOddsRatio(selectedFarBelow, 0.7, 0.7) - 1e-9) / 1e-9 < 1e-6)
    }

    @Test func bothBranchesAreNamed() {
        #expect(PlackettRoot.Branch.allCases.map(\.rawValue) == ["textbook", "rationalised"])
    }

    @Test func theSelectorSwitchesOnTheSignOfTheLinearTerm() {
        // `t < 0` needs `psi < 1` and rates summing above one, so both regimes are reached.
        #expect(PlackettRoot.jointProbability(oddsRatio: 0.5, first: 0.7, second: 0.7)
            == PlackettRoot.evaluate(.rationalised, oddsRatio: 0.5, first: 0.7, second: 0.7))
        #expect(PlackettRoot.jointProbability(oddsRatio: 0.001, first: 0.7, second: 0.7)
            == PlackettRoot.evaluate(.textbook, oddsRatio: 0.001, first: 0.7, second: 0.7))
    }
}
