/**
 * @name In-place mutation of dict.get() return value
 * @description Detects when the return value of dict.get() is mutated
 *              in-place, corrupting the original dictionary contents.
 * @kind problem
 * @problem.severity error
 * @id python/dict-value-mutation
 * @tags security
 *       correctness
 */

import python

// Chamadas ao método .get() em qualquer objeto
predicate isDictGet(Call getCall, Expr dictObj) {
    exists(Attribute attr |
        attr = getCall.getFunc() and
        attr.getName() = "get" and
        dictObj = attr.getObject()
    )
}

// Métodos que mutam listas/sets in-place
predicate isMutatingMethod(string name) {
    name in ["append", "extend", "update", "add", "insert",
             "remove", "pop", "clear", "sort", "reverse"]
}

// Atribuição: var = dict.get(...)
// seguida de: var.mutate(...)
from AssignStmt assign, Call getCall, Call mutCall,
     Name assignTarget, Attribute mutAttr, Expr dictObj
where
    isDictGet(getCall, dictObj) and
    assign.getValue() = getCall and
    assignTarget = assign.getTarget(0) and
    mutAttr = mutCall.getFunc() and
    mutAttr.getObject().(Name).getId() = assignTarget.getId() and
    isMutatingMethod(mutAttr.getName()) and
    assign.getLocation().getFile() = mutCall.getLocation().getFile() and
    assign.getLocation().getStartLine() < mutCall.getLocation().getStartLine()
select assign,
    "Return value of '" + dictObj.toString() +
    ".get()' is mutated in-place by '." + mutAttr.getName() +
    "()' at line " + mutCall.getLocation().getStartLine().toString() +
    " — original dictionary contents are corrupted."
