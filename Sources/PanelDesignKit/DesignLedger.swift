import Foundation

/// Records fixtures, says what each one can carry, and builds a replacement when it can carry nothing.
///
/// The asymmetry this series uses one level down applies here too. **Diagnosing** a fixture is
/// arithmetic and always available: any panel will produce deviations, agreement rates and
/// coefficients. **Certifying** one — putting a coefficient on a page and letting a reader take
/// it as a statement about the judges — is a claim that the panel had association in it to find.
/// Only ``certify(_:)`` makes that claim, and it is the only call here that can refuse.
public actor DesignLedger {

    private var panels: [String: PanelMatrix] = [:]

    public init() {}

    /// Records `panel` under `key`, replacing anything already held there.
    public func record(_ key: String, panel: PanelMatrix) {
        panels[key] = panel
    }

    /// Every recorded key, in a stable order.
    public func keys() -> [String] { panels.keys.sorted() }

    /// The diagnosis. Always available, because diagnosing is not certifying.
    ///
    /// - Throws: ``PanelDesignError/unknownPanel(_:)``.
    public func diagnosis(for key: String) throws -> DesignDiagnosis {
        try DesignDiagnosis(panel: try panel(for: key))
    }

    /// The diagnosis, or a refusal if the fixture is structurally null.
    ///
    /// - Throws: ``PanelDesignError/unknownPanel(_:)`` or
    ///   ``PanelDesignError/designCarriesNoAssociation(judges:deviation:)``.
    public func certify(_ key: String) throws -> DesignDiagnosis {
        try diagnosis(for: key).certify()
    }

    /// A two-judge fixture with the same marginals as `pair` in the recorded panel, and `target`
    /// in it.
    ///
    /// This is the recovery action that goes with the refusal. A null fixture is not fixed by
    /// relabelling it or by measuring something else; it is fixed by building a panel that holds
    /// the judges' own rates and puts association between them, which is what the caller thought
    /// they had.
    ///
    /// - Throws: ``PanelDesignError/unknownPanel(_:)``, whatever ``PanelMatrix/margin(_:)``
    ///   refuses, and whatever ``BinaryPanelBuilder`` refuses.
    public func replacement(
        for key: String,
        pair: (Int, Int),
        target: AssociationTarget,
        seed: UInt64
    ) throws -> BinaryConstruction {
        let recorded = try panel(for: key)
        guard pair.0 != pair.1 else {
            throw PanelDesignError.judgePairNotDistinct(pair.0)
        }
        let builder = try BinaryPanelBuilder(
            first: try recorded.margin(pair.0), second: try recorded.margin(pair.1)
        )
        return try builder.table(for: target)
    }

    /// Records the realisation of `construction` under `key` and returns its diagnosis.
    ///
    /// - Throws: whatever ``PanelRealization/matrix()`` or ``DesignDiagnosis/init(panel:)``
    ///   refuses.
    @discardableResult
    public func adopt(
        _ key: String, construction: BinaryConstruction, seed: UInt64
    ) throws -> DesignDiagnosis {
        let matrix = try PanelRealization(table: construction.table, seed: seed).matrix()
        panels[key] = matrix
        return try DesignDiagnosis(panel: matrix)
    }

    private func panel(for key: String) throws -> PanelMatrix {
        guard let recorded = panels[key] else {
            throw PanelDesignError.unknownPanel(key)
        }
        return recorded
    }
}
