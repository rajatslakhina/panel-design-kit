import Testing
@testable import PanelDesignKit

@Suite("The design ledger")
struct LedgerTests {

    @Test func diagnosingIsFreeAndCertifyingIsNot() async throws {
        let ledger = DesignLedger()
        await ledger.record("crossed", panel: try DesignTests.crossed(judges: 3, repeats: 25))
        let diagnosis = try await ledger.diagnosis(for: "crossed")
        #expect(diagnosis.isStructurallyNull)
        await #expect(throws: PanelDesignError.designCarriesNoAssociation(judges: 3, deviation: 0)) {
            _ = try await ledger.certify("crossed")
        }
        #expect(await ledger.keys() == ["crossed"])
    }

    @Test func anUnknownKeyIsRefused() async {
        let ledger = DesignLedger()
        await #expect(throws: PanelDesignError.unknownPanel("missing")) {
            _ = try await ledger.diagnosis(for: "missing")
        }
        await #expect(throws: PanelDesignError.unknownPanel("missing")) {
            _ = try await ledger.replacement(
                for: "missing", pair: (0, 1), target: .independence, seed: 1
            )
        }
    }

    @Test func recordingReplacesWhatWasThere() async throws {
        let ledger = DesignLedger()
        await ledger.record("panel", panel: try DesignTests.crossed(judges: 2, repeats: 8))
        await ledger.record(
            "panel",
            panel: try PanelMatrix(labels: [[0, 0, 0, 1], [0, 0, 1, 1]], categoryCount: 2)
        )
        #expect(try await ledger.diagnosis(for: "panel").itemCount == 4)
    }

    @Test func aRefusedFixtureIsReplacedRatherThanArguedWith() async throws {
        let ledger = DesignLedger()
        await ledger.record("crossed", panel: try DesignTests.crossed(judges: 3, repeats: 25))
        let replacement = try await ledger.replacement(
            for: "crossed", pair: (0, 1), target: .oddsRatio(6), seed: 20_260_907
        )
        #expect(replacement.table.rowMargin.counts == [100, 100])
        #expect(replacement.table.columnMargin.counts == [100, 100])
        #expect(replacement.table.cells == [[71, 29], [29, 71]])
        let adopted = try await ledger.adopt(
            "rebuilt", construction: replacement, seed: 20_260_907
        )
        #expect(adopted.maximumPairDeviation == 21)
        #expect(!adopted.isFullyCrossed)
        _ = try await ledger.certify("rebuilt")
        #expect(await ledger.keys() == ["crossed", "rebuilt"])
    }

    @Test func aReplacementNeedsTwoDistinctJudges() async throws {
        let ledger = DesignLedger()
        await ledger.record("crossed", panel: try DesignTests.crossed(judges: 3, repeats: 25))
        await #expect(throws: PanelDesignError.judgePairNotDistinct(1)) {
            _ = try await ledger.replacement(
                for: "crossed", pair: (1, 1), target: .independence, seed: 1
            )
        }
        await #expect(throws: PanelDesignError.judgeOutOfRange(7)) {
            _ = try await ledger.replacement(
                for: "crossed", pair: (7, 1), target: .independence, seed: 1
            )
        }
    }
}
