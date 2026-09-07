import Testing
@testable import PanelDesignKit

@Suite("Diagnosing a fixture")
struct DesignTests {

    static func crossed(judges: Int, repeats: Int) throws -> PanelMatrix {
        let combinations = 1 << judges
        var labels = [[Int]](repeating: [], count: judges)
        for _ in 0..<repeats {
            for combination in 0..<combinations {
                for judge in 0..<judges {
                    labels[judge].append((combination >> (judges - 1 - judge)) & 1)
                }
            }
        }
        return try PanelMatrix(labels: labels, categoryCount: 2)
    }

    @Test func aPanelIsValidatedOnce() throws {
        let panel = try PanelMatrix(labels: [[0, 1, 1, 0], [1, 1, 0, 0]], categoryCount: 2)
        #expect(panel.judgeCount == 2)
        #expect(panel.itemCount == 4)
        #expect(try panel.margin(0).counts == [2, 2])
        #expect(try panel.table(0, 1).cells == [[1, 1], [1, 1]])
    }

    @Test func badPanelsAreRefused() {
        #expect(throws: PanelDesignError.judgeCountTooSmall(1)) {
            _ = try PanelMatrix(labels: [[0, 1]], categoryCount: 2)
        }
        #expect(throws: PanelDesignError.categoryCountTooSmall(1)) {
            _ = try PanelMatrix(labels: [[0, 0], [0, 0]], categoryCount: 1)
        }
        #expect(throws: PanelDesignError.itemCountTooSmall(1)) {
            _ = try PanelMatrix(labels: [[0], [1]], categoryCount: 2)
        }
        #expect(throws: PanelDesignError.itemCountMismatch(first: 2, second: 3)) {
            _ = try PanelMatrix(labels: [[0, 1], [0, 1, 1]], categoryCount: 2)
        }
        #expect(throws: PanelDesignError.labelOutOfRange(judge: 1, item: 1, label: 4)) {
            _ = try PanelMatrix(labels: [[0, 1], [1, 4]], categoryCount: 2)
        }
    }

    @Test func judgeIndicesAreChecked() throws {
        let panel = try PanelMatrix(labels: [[0, 1, 1, 0], [1, 1, 0, 0]], categoryCount: 2)
        #expect(throws: PanelDesignError.judgeOutOfRange(5)) { _ = try panel.margin(5) }
        #expect(throws: PanelDesignError.judgeOutOfRange(-1)) { _ = try panel.table(-1, 0) }
        #expect(throws: PanelDesignError.judgeOutOfRange(9)) { _ = try panel.table(0, 9) }
        #expect(throws: PanelDesignError.judgePairNotDistinct(1)) { _ = try panel.table(1, 1) }
    }

    @Test func aCrossedFixtureIsExactlyIndependentOnEveryPair() throws {
        let diagnosis = try DesignDiagnosis(panel: Self.crossed(judges: 3, repeats: 25))
        #expect(diagnosis.judgeCount == 3)
        #expect(diagnosis.itemCount == 200)
        #expect(diagnosis.deviations.count == 3)
        #expect(diagnosis.isFullyCrossed)
        #expect(diagnosis.maximumPairDeviation == 0)
        #expect(diagnosis.isStructurallyNull)
        for deviation in diagnosis.deviations {
            #expect(deviation.deviation == 0)
            #expect(deviation.agreementRate == 0.5)
            #expect(deviation.cohenKappa == 0)
        }
        #expect(diagnosis.strongestPair?.deviation == 0)
    }

    @Test func certifyingANullFixtureIsTheOneRefusal() throws {
        let diagnosis = try DesignDiagnosis(panel: Self.crossed(judges: 2, repeats: 8))
        #expect(throws: PanelDesignError.designCarriesNoAssociation(judges: 2, deviation: 0)) {
            _ = try diagnosis.certify()
        }
    }

    @Test func aFixtureWithAssociationCertifies() throws {
        let panel = try PanelMatrix(
            labels: [[0, 0, 0, 1, 1, 1], [0, 0, 0, 1, 1, 0]], categoryCount: 2
        )
        let diagnosis = try DesignDiagnosis(panel: panel).certify()
        #expect(!diagnosis.isStructurallyNull)
        #expect(!diagnosis.isFullyCrossed)
        #expect(diagnosis.strongestPair?.first == 0)
    }

    @Test func crossingIsRejectedWhenTheCountsDoNotDivide() throws {
        let panel = try PanelMatrix(
            labels: [[0, 0, 1, 1, 0], [0, 1, 0, 1, 1]], categoryCount: 2
        )
        #expect(!(try DesignDiagnosis(panel: panel).isFullyCrossed))
    }

    @Test func crossingIsRejectedWhenACombinationIsMissing() throws {
        let panel = try PanelMatrix(
            labels: [[0, 0, 1, 1], [0, 0, 1, 1]], categoryCount: 2
        )
        #expect(!(try DesignDiagnosis(panel: panel).isFullyCrossed))
    }

    @Test func crossingIsRejectedWhenThereAreMoreCombinationsThanItems() throws {
        let panel = try PanelMatrix(
            labels: [[0, 1], [1, 0], [0, 0], [1, 1]], categoryCount: 2
        )
        #expect(!(try DesignDiagnosis(panel: panel).isFullyCrossed))
    }
}
