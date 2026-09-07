import Foundation
import PanelDesignKit

/// One named pair of marginals for the attainable-range table.
struct PanelSpec {
    let name: String
    let items: Int
    let first: Int
    let second: Int
}

enum DemoScenarios {

    static func crossedFixture(_ panel: PanelMatrix) throws -> String {
        let diagnosis = DesignDiagnosis(panel: panel)
        var lines = [Format.heading("A. The fixture three gates were crossed into")]
        let header = "judges \(diagnosis.judgeCount)   items \(diagnosis.itemCount)"
        lines.append(header + "   fully crossed \(diagnosis.isFullyCrossed)")
        lines.append("")
        lines.append(Format.row(["pair", "agree", "kappa", "max |obs - exp|"], widths: [10, 10, 10, 18]))
        for deviation in diagnosis.deviations {
            lines.append(
                Format.row(
                    [
                        "\(deviation.first)-\(deviation.second)",
                        Format.fixed(deviation.agreementRate),
                        deviation.cohenKappa.map { Format.fixed($0) } ?? "n/a",
                        Format.fixed(deviation.deviation, 6)
                    ],
                    widths: [10, 10, 10, 18]
                )
            )
        }
        lines.append("")
        lines.append("largest deviation anywhere: \(Format.fixed(diagnosis.maximumPairDeviation, 6))")
        lines.append("structurally null: \(diagnosis.isStructurallyNull)")
        return lines.joined(separator: "\n")
    }

    static func attainable(_ cases: [PanelSpec]) throws -> String {
        var lines = [Format.heading("B. What two marginals allow before either judge speaks")]
        lines.append(
            Format.row(["panel", "n", "a+", "b+", "lower", "upper", "step", "count", "pinned"],
                       widths: [22, 6, 6, 6, 8, 8, 6, 7, 8])
        )
        for spec in cases {
            let first = try MarginalProfile.binary(positives: spec.first, items: spec.items)
            let second = try MarginalProfile.binary(positives: spec.second, items: spec.items)
            let range = try AttainableAgreement(first: first, second: second)
            lines.append(
                Format.row(
                    [
                        spec.name, String(spec.items), String(spec.first), String(spec.second),
                        Format.fixed(range.lower), Format.fixed(range.upper),
                        range.step.map(String.init) ?? "-",
                        String((range.attainableCounts ?? []).count),
                        String(range.isPinned)
                    ],
                    widths: [22, 6, 6, 6, 8, 8, 6, 7, 8]
                )
            )
        }
        return lines.joined(separator: "\n")
    }

    static func lattice(_ builder: BinaryPanelBuilder) -> String {
        let range = builder.attainable
        var lines = [Format.heading("C. The lattice a two-category panel puts under every request")]
        let counts = range.attainableCounts ?? []
        let head = counts.prefix(4).map(String.init).joined(separator: ", ")
        let span = range.upperCount - range.lowerCount + 1
        lines.append("attainable agreement counts: \(head) ... \(range.upperCount)")
        lines.append("that is \(counts.count) of the \(span) integers in range; the rest do not exist")
        lines.append("")
        lines.append(Format.row(["requested", "built", "count", "snap"], widths: [12, 10, 8, 12]))
        for rate in [0.7000, 0.7050, 0.7100, 0.7150] {
            guard let built = try? builder.table(for: .agreementRate(rate)) else { continue }
            lines.append(
                Format.row(
                    [Format.fixed(rate), Format.fixed(built.agreementRate),
                     String(built.diagonalTotal), Format.fixed(built.snapDistance)],
                    widths: [12, 10, 8, 12]
                )
            )
        }
        return lines.joined(separator: "\n")
    }

    static func construction(_ builder: BinaryPanelBuilder) throws -> String {
        var lines = [Format.heading("D. Fixtures built to a target, and what the integers do to it")]
        lines.append(
            Format.row(["target", "agree", "kappa", "odds ratio", "max dev"], widths: [20, 10, 10, 12, 10])
        )
        let targets: [(String, AssociationTarget)] = [
            ("independence", .independence),
            ("odds ratio 0.25", .oddsRatio(0.25)),
            ("odds ratio 1", .oddsRatio(1)),
            ("odds ratio 4", .oddsRatio(4)),
            ("odds ratio 25", .oddsRatio(25)),
            ("agreement 0.85", .agreementRate(0.85))
        ]
        for (name, target) in targets {
            let built = try builder.table(for: target)
            let odds = (try? built.table.oddsRatio()).map { Format.fixed($0) } ?? "undefined"
            lines.append(
                Format.row(
                    [
                        name, Format.fixed(built.agreementRate),
                        built.table.cohenKappa.map { Format.fixed($0) } ?? "n/a",
                        odds, Format.fixed(built.table.maximumIndependenceDeviation, 4)
                    ],
                    widths: [20, 10, 10, 12, 10]
                )
            )
        }
        let independent = try builder.table(for: .independence)
        let gap = Format.fixed(independent.table.maximumIndependenceDeviation, 4)
        let product = Double(builder.first.counts[0] * builder.second.counts[0])
        let predicted = Format.fixed(product / Double(builder.attainable.itemCount), 2)
        lines.append("")
        lines.append("the independence target lands \(gap) off exact,")
        lines.append("because a * b / n = \(predicted) is not a whole number of items.")
        return lines.joined(separator: "\n")
    }

    static func plackettBranches(first p1: Double, second p2: Double) -> String {
        var lines = [Format.heading("E. Two algebraic forms of one root, each wrong where the other is right")]
        lines.append("Frechet interval for the joint cell: " +
                     "[\(Format.fixed(max(0, p1 + p2 - 1))), \(Format.fixed(min(p1, p2)))]")
        lines.append("residual = |odds ratio implied by the cell - the one asked for| / the one asked for")
        lines.append("")
        lines.append(
            Format.row(["odds ratio", "textbook", "rationalised", "resid textbook", "resid ration."],
                       widths: [14, 14, 14, 16, 16])
        )
        for psi in [1e-9, 1e-6, 0.001, 0.5, 1 - 1e-13, 1.0, 1 + 1e-13, 4.0, 1e6] {
            let textbook = PlackettRoot.evaluate(.textbook, oddsRatio: psi, first: p1, second: p2)
            let rationalised = PlackettRoot.evaluate(.rationalised, oddsRatio: psi, first: p1, second: p2)
            lines.append(
                Format.row(
                    [
                        Format.scientific(psi), Format.fixed(textbook, 9), Format.fixed(rationalised, 9),
                        Format.scientific(residual(textbook, psi, p1, p2)),
                        Format.scientific(residual(rationalised, psi, p1, p2))
                    ],
                    widths: [14, 14, 14, 16, 16]
                )
            )
        }
        let near = PlackettRoot.evaluate(.textbook, oddsRatio: 1 - 1e-13, first: p1, second: p2)
        let selected = PlackettRoot.jointProbability(oddsRatio: 1 - 1e-13, first: p1, second: p2)
        lines.append("")
        let exact = Format.fixed(p1 * p2, 12)
        lines.append("at psi = 1 - 1e-13 the exact cell is p1 * p2 = \(exact);")
        lines.append("textbook reads \(Format.fixed(near, 12)), relative error " +
                     "\(Format.scientific(abs(near - p1 * p2) / (p1 * p2))); selected reads " +
                     "\(Format.fixed(selected, 12)).")
        return lines.joined(separator: "\n")
    }

    /// The odds ratio a joint cell implies, checked against the one that was asked for.
    ///
    /// No reference value is needed: the cell either reproduces its own odds ratio or it does not.
    private static func residual(_ joint: Double, _ psi: Double, _ p1: Double, _ p2: Double) -> Double {
        let implied = joint * (1 - p1 - p2 + joint) / ((p1 - joint) * (p2 - joint))
        return abs(implied - psi) / psi
    }

    static func refusals(
        _ builder: BinaryPanelBuilder, _ ternary: PanelMatrix, _ crossed: PanelMatrix
    ) async -> String {
        var lines = [Format.heading("F. Every way this package says no")]
        lines.append(attempt("agreement rate 0.10, below the floor") {
            _ = try builder.table(for: .agreementRate(0.10))
        })
        lines.append(attempt("agreement count 100, off the lattice") {
            _ = try builder.table(diagonalTotal: 100)
        })
        lines.append(attempt("odds ratio of zero") {
            _ = try builder.table(for: .oddsRatio(0))
        })
        lines.append(attempt("construction on a three-category panel") {
            _ = try BinaryPanelBuilder(first: try ternary.margin(0), second: try ternary.margin(1))
        })
        lines.append(attempt("construction against a judge who affirmed everything") {
            let constant = try MarginalProfile.binary(positives: 200, items: 200)
            let other = try MarginalProfile.binary(positives: 120, items: 200)
            _ = try BinaryPanelBuilder(first: constant, second: other)
        })
        lines.append(attempt("odds ratio of a table with an empty cell") {
            _ = try JointTable(cells: [[100, 0], [40, 60]]).oddsRatio()
        })
        lines.append(attempt("certifying the crossed fixture") {
            _ = try DesignDiagnosis(panel: crossed).certify()
        })
        return lines.joined(separator: "\n")
    }

    static func ledger(_ crossed: PanelMatrix, seed: UInt64) async throws -> String {
        let ledger = DesignLedger()
        await ledger.record("crossed", panel: crossed)
        var lines = [Format.heading("G. Refuse the fixture, then build the one that answers the question")]
        let before = try await ledger.diagnosis(for: "crossed")
        let deviation = Format.fixed(before.maximumPairDeviation, 6)
        lines.append("recorded fixture: \(before.judgeCount) judges, deviation \(deviation)")
        lines.append(await attempt("certify") { _ = try await ledger.certify("crossed") })
        let replacement = try await ledger.replacement(
            for: "crossed", pair: (0, 1), target: .oddsRatio(6), seed: seed
        )
        let adopted = try await ledger.adopt("rebuilt", construction: replacement, seed: seed)
        lines.append("")
        lines.append("rebuilt on the same two marginals, targeting an odds ratio of 6:")
        lines.append(Format.table(replacement.table.cells))
        lines.append("agreement \(Format.fixed(replacement.agreementRate))   " +
                     "kappa \(replacement.table.cohenKappa.map { Format.fixed($0) } ?? "n/a")   " +
                     "odds ratio \(Format.fixed((try? replacement.table.oddsRatio()) ?? 0))")
        let now = Format.fixed(adopted.maximumPairDeviation, 6)
        lines.append("deviation now \(now); fully crossed \(adopted.isFullyCrossed)")
        _ = try await ledger.certify("rebuilt")
        lines.append("certify(rebuilt): passed")
        lines.append("keys held: \(await ledger.keys().joined(separator: ", "))")
        return lines.joined(separator: "\n")
    }

    private static func attempt(_ label: String, _ body: () throws -> Void) -> String {
        do {
            try body()
            return Format.pad(label, 52) + "  no refusal"
        } catch let error as PanelDesignError {
            return Format.pad(label, 52) + "  \(error)"
        } catch {
            return Format.pad(label, 52) + "  \(error)"
        }
    }

    private static func attempt(_ label: String, _ body: () async throws -> Void) async -> String {
        do {
            try await body()
            return Format.pad(label, 52) + "  no refusal"
        } catch let error as PanelDesignError {
            return Format.pad(label, 52) + "  \(error)"
        } catch {
            return Format.pad(label, 52) + "  \(error)"
        }
    }
}
