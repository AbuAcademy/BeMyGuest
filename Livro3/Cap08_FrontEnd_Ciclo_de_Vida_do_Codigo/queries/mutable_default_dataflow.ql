/**
 * @name Mutable default argument with in-place mutation
 * @description Detects mutable default arguments that are mutated directly,
 *              via augmented assignment, or through a helper function call.
 * @kind problem
 * @problem.severity error
 * @id python/mutable-default-dataflow
 * @tags security
 */

import python

// Funções com argumento padrão mutável (lista)
predicate hasMutableDefault(Function func, Parameter param) {
    param = func.getArgByName(_) and
    param.getDefault() instanceof List
}

// Mutação direta: acl.append(...) ou acl.extend(...)
predicate directMutation(Parameter param, Call mutation) {
    exists(Attribute attr |
        attr = mutation.getFunc() and
        attr.getObject().(Name).getId() = param.asName().getId() and
        attr.getName() in ["append", "extend", "insert", "remove",
                           "pop", "clear", "sort", "reverse"]
    )
}

// Augmented assignment: acl += [...]
predicate augmentedAssignment(Parameter param, AugAssign aug) {
    aug.getTarget().(Name).getId() = param.asName().getId()
}

// Passagem para helper: return _merge_grants(acl, ...) onde helper chama .extend()
predicate flowsToHelper(Parameter param, Call outer, Call inner) {
    exists(int i, Function helper, Parameter helperParam |
        outer.getArg(i).(Name).getId() = param.asName().getId() and
        outer.getFunc().(Name).getId() = helper.getName() and
        helperParam = helper.getArgByName(_) and
        directMutation(helperParam, inner)
    )
}

from Function func, Parameter param
where
    hasMutableDefault(func, param) and
    (
        exists(Call c | directMutation(param, c)) or
        exists(AugAssign a | augmentedAssignment(param, a)) or
        exists(Call outer, Call inner | flowsToHelper(param, outer, inner))
    )
select param,
    "Parameter '" + param.asName().getId() + "' in '" + func.getName() +
    "' has a mutable default that is mutated — shared state persists across calls."
