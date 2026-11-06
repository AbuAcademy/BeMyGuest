import python
import semmle.python.dataflow.new.DataFlow

/**
 * @name Evasão de Firewall por Decomposição Lógica
 * @description Detecta quando checagens de IP e porta são isoladas em variáveis,
 * mas recombinadas incorretamente no retorno, mantendo o bypass vivo.
 */

// 1. Corrigido: usando getOp(_) para casar com qualquer operador da comparação
predicate isIpCheck(DataFlow::Node node) {
  exists(Compare comp |
    comp.getOp(_) instanceof In and
    node.asExpr() = comp
  )
}

// 2. Aqui continua igual, pois BoolExpr só tem um operador central (And/Or) e usa getOp()
predicate isPortMitigatedCheck(DataFlow::Node node) {
  exists(BoolExpr andExpr |
    andExpr.getOp() instanceof And and
    node.asExpr() = andExpr
  )
}

from DataFlow::Node ipSource, DataFlow::Node portSource, Return ret, BoolExpr orExpr, Function func
where
  isIpCheck(ipSource) and
  isPortMitigatedCheck(portSource) and
  ret.getValue() = orExpr and
  orExpr.getOp() instanceof Or and
  func = ret.getScope() and 
  // Rastreia se os valores lógicos dessas checagens fluíram para os operandos do OR no return
  DataFlow::localFlow(ipSource, DataFlow::exprNode(orExpr.getValue(_))) and
  DataFlow::localFlow(portSource, DataFlow::exprNode(orExpr.getValue(_)))
select ret, "Logic flaw in '" + func.getName() + "': decomposition into intermediate variables maintained the firewall bypass via unsafe 'or' condition."
