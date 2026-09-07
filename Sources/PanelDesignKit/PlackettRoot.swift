import Foundation

/// The joint cell of a two-by-two distribution with given margins and a given odds ratio.
///
/// Plackett's construction solves a quadratic, and the quadratic has a textbook form that is
/// printed everywhere and is wrong in floating point over a large part of its own domain. Both
/// forms are exact in real arithmetic and each one cancels catastrophically where the other
/// does not, so the useful thing is not a formula but the test that picks between them.
public enum PlackettRoot {

    /// Which algebraic form of the same root to evaluate.
    public enum Branch: String, Sendable, CaseIterable {

        /// `(t - s) / (2(psi - 1))`, the form printed in the literature.
        ///
        /// `t` and `s` both approach one as the odds ratio approaches one, so the numerator is
        /// a difference of nearly equal quantities divided by a vanishing denominator. It also
        /// needs a special case at `psi == 1`, where it is `0 / 0`.
        case textbook

        /// `2 psi p1 p2 / (t + s)`, the same root with the numerator rationalised.
        ///
        /// Continuous at `psi == 1`, where it evaluates to `p1 * p2` with no special case. It
        /// cancels instead when `t` is negative and `s` is close to `-t`, which happens for
        /// small odds ratios on panels where the two rates sum to more than one.
        case rationalised
    }

    /// The root, evaluated on the branch that does not cancel.
    ///
    /// The selector is the sign of `t = 1 + (p1 + p2)(psi - 1)`. When `t` is non-negative,
    /// `t + s` adds two non-negative quantities and the rationalised form is exact to the last
    /// digit it can be. When `t` is negative, `s` is positive and `t - s` subtracts nothing, so
    /// the textbook form is the clean one — and `t < 0` forces `psi < 1`, so its denominator is
    /// safely away from zero. **One comparison covers the whole domain.**
    public static func jointProbability(oddsRatio psi: Double, first p1: Double, second p2: Double) -> Double {
        discriminant(oddsRatio: psi, first: p1, second: p2).0 >= 0
            ? evaluate(.rationalised, oddsRatio: psi, first: p1, second: p2)
            : evaluate(.textbook, oddsRatio: psi, first: p1, second: p2)
    }

    /// The root on a named branch, whether or not that branch is the stable one here.
    ///
    /// Public because the comparison is the point. A caller that wants to see how far the
    /// printed formula drifts near `psi == 1` has to be able to evaluate it.
    public static func evaluate(
        _ branch: Branch, oddsRatio psi: Double, first p1: Double, second p2: Double
    ) -> Double {
        let (t, s) = discriminant(oddsRatio: psi, first: p1, second: p2)
        switch branch {
        case .textbook:
            guard psi != 1 else { return p1 * p2 }
            return (t - s) / (2 * (psi - 1))
        case .rationalised:
            return 2 * psi * p1 * p2 / (t + s)
        }
    }

    private static func discriminant(
        oddsRatio psi: Double, first p1: Double, second p2: Double
    ) -> (Double, Double) {
        let t = 1 + (p1 + p2) * (psi - 1)
        let s = (t * t - 4 * psi * (psi - 1) * p1 * p2).squareRoot()
        return (t, s)
    }
}
