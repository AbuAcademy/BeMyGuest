/**
 * @name Ambiguous boolean precedence in security-sensitive return
 * @description Detects return statements mixing 'or' and 'and' without
 *              explicit parentheses, where implicit precedence may diverge
 *              from documented intent.
 * @kind problem
 * @problem.severity warning
 * @id python/bool-precedence-ambiguous
 * @tags security
 *       correctness
 */

import python

// BoolExpr com 'or' no topo que contém 'and' num dos operandos
// sem parênteses explícitos — estrutura: A or B and C
predicate ambiguousBoolExpr(BoolExpr outer, BoolExpr inner) {
    outer.getOp() instanceof Or and
    inner.getOp() instanceof And and
    (
        outer.getValue(0) = inner or
        outer.getValue(1) = inner or
        outer.getValue(2) = inner
    ) and
    // exclui casos onde o 'and' está explicitamente entre parênteses
    not exists(Tuple t | t.getAnElt() = inner)
}

from Return ret, BoolExpr outer, BoolExpr inner
where
    ret.getValue() = outer and
    ambiguousBoolExpr(outer, inner)
select ret,
    "Return statement mixes 'or' and 'and' without explicit parentheses — " +
    "implicit precedence evaluates 'and' first, which may diverge from intent."
