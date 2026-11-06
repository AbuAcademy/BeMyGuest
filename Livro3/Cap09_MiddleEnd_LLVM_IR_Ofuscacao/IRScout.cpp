// IRScout.cpp — reconnaissance pass: mapeia funções de interesse
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

// Padrões que indicam funções de alto valor ofensivo
static const char *HighValueTargets[] = {
    "main",           // ponto de entrada universal
    "auth",           // autenticação
    "login",          // login
    "verify",         // verificação de credencial / token
    "encrypt",        // criptografia
    "decrypt",        // descriptografia
    "sign",           // assinatura digital
    "token",          // geração / validação de token
    "session",        // gerenciamento de sessão
    "handle_request", // handler de rede
    "password",       // manipulação de senha
    nullptr
};

struct IRScout : PassInfoMixin<IRScout> {
    PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
        errs() << "[IRScout] Módulo: " << M.getName()
               << " | Triple: "       << M.getTargetTriple().str() << "\n";

        for (Function &F : M) {
            if (F.isDeclaration()) continue;

            StringRef Name = F.getName();
            for (int i = 0; HighValueTargets[i] != nullptr; i++) {
                if (Name.contains_insensitive(HighValueTargets[i])) {
                    errs() << "  --> ALVO: " << Name
                           << " | BBs: "     << F.size()
                           << " | args: "    << F.arg_size() << "\n";

                    BasicBlock &Entry = F.getEntryBlock();
                    errs() << "      Entry block: "
                           << Entry.size() << " instruções\n";

                    for (Instruction &I : Entry)
                        if (auto *Call = dyn_cast<CallInst>(&I))
                            if (Function *Callee = Call->getCalledFunction())
                                errs() << "      → chama: "
                                       << Callee->getName() << "\n";
                    break;
                }
            }
        }
        return PreservedAnalyses::all(); // reconnaissance — não modifica
    }
};

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "IRScout", "0.1",
        [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                    MPM.addPass(IRScout());
                });
        }
    };
}
